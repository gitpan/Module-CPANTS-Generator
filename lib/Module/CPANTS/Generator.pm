package Module::CPANTS::Generator;
use strict;
use warnings;
use Carp;
use Cwd;
use Storable;
use Data::Dumper;
use base qw(Class::Accessor Class::Data::Inheritable);

use YAML;

use File::Copy;
use File::Path;
use File::Spec::Functions qw(catdir catfile);
use CPAN::DistnameInfo;
use AppConfig qw(:expand :argcount);
use FindBin;

use DateTime;

use vars qw($VERSION);
$VERSION = "0.23";


##################################################################
# SETUP - AUTOMATIC
##################################################################

#-----------------------------------------------------------------
# set up classdata and accessors
#-----------------------------------------------------------------
my $class=__PACKAGE__;

foreach (qw(DBH tempdir distsdir testdir metricdir conf available_generators kwalitee_definitions cpan_backend)) {
    $class->mk_classdata($_);
}

$class->mk_accessors
  (qw(package dist temppath distnameinfo metricfile abort files dirs));


#-----------------------------------------------------------------
# parse command line options
#-----------------------------------------------------------------
{
    my $config=AppConfig->new();
    $config->define
      (qw(force reload_cpan no_authors no_bar print_distname),
       qw(limit=s),
       'tempdir=s'=>{DEFAULT=>'temp'},
       'distsdir=s'=>{DEFAULT=>'dists'},
       'metricdir=s'=>{DEFAULT=>'metrics'},
       'cpan=s'=>{DEFAULT=>'/home/cpan/'},
       'generators=@'=>{DEFAULT=>[qw(Unpack Files FindModules Pod Prereq CPAN)]}
      );
    $config->args;
    $class->conf($config);
}

##################################################################
# SETUP - HAS TO BE CALLED EXPLICTLY
##################################################################

#-----------------------------------------------------------------
# set up various directories
#-----------------------------------------------------------------
sub setup_dirs {
    my $base=$FindBin::Bin;

    $class->distsdir(catdir($base,$class->conf->distsdir));
    croak("I cannot do my work without a distsdir") unless (-e $class->distsdir);

    $class->metricdir(catdir($base,$class->conf->metricdir));
    if (!-e $class->metricdir) {
	mkdir($class->metricdir) || croak "cannot make metricdir: ".$class->metricdir.": $!";
    }

    $class->tempdir(catdir($base,$class->conf->tempdir));
    if (!-e $class->tempdir) {
	mkdir($class->tempdir) || croak "cannot make tempdir: ".$class->tempdir.": $!";
    }
}


#-----------------------------------------------------------------
# cpanplus
#-----------------------------------------------------------------
sub get_cpan_backend {
    my $self=shift;

    if ($self->cpan_backend) {
	return $self->cpan_backend;
    }

    my $cp=CPANPLUS::Backend->new(conf => {verbose => 0, debug => 0});
    $self->cpan_backend($cp);

    # set local cpan mirror if there is one - RECOMMENDED
    if (my $local_cpan=$self->conf->cpan) {
	my $cp_conf=$cp->configure_object;
	$cp_conf->_set_ftp(urilist=>
			   [{
			     scheme => 'file',
			     path   => $local_cpan,
			    }]);
    }
    return $cp;
}



##################################################################
# Instance Methods
##################################################################

sub new {
    my $class=shift;
    my $package=shift;
    my $temppath=catfile($class->tempdir,$package);

    my $self=bless {
		    package=>$package,
		    temppath=>$temppath,
		   },$class;

    my $di=CPAN::DistnameInfo->new($package);
    $self->distnameinfo($di);
    $self->dist($di->distvname || $package);

    $self->metricfile(catfile($class->metricdir,$self->dist.'.yml'));

    return $self;
}


#-----------------------------------------------------------------
# write_metric
#-----------------------------------------------------------------
sub write_metric {
    my $proto=shift;
    my ($metric,$file);
    if (ref($proto)) {
	$file=$proto->metricfile;
	$metric=$proto->{metric};
    } else {
	$metric=shift;
	$file=catfile($proto->metricdir, $metric->{dist}.'.yml');
    }

    $metric->{generated_at}=DateTime->now->datetime;
    $metric->{generated_with}="Module::CPANTS::Generator ".$VERSION;

    open(OUT,">$file") || croak("Cannot write metrics to $file: $!");
    print OUT Dump($metric);
    close OUT;
}



##################################################################
# Class Methods
##################################################################

sub tidytemp {
    my $self=shift;
    rmtree($self->tempdir) || die "ERROR $!";
    mkdir($class->tempdir) || die "ERROR $!";
    return;
}



sub load_generators {
    my $self=shift;
    my $generators=$self->conf->generators;

#    print "Loading Generators.\n" unless $self->conf->quiet;

    {
	no strict 'refs';
	foreach my $gen (@$generators) {
	    $gen="Module::CPANTS::Generator::$gen";
	    eval "require $gen";
	    croak "cannot load $gen\n$@" if $@;
#	    print "+ loaded $gen\n" if $self->conf->verbose;
	}
    }

    $self->available_generators($generators);
    return;
}


sub kwalitee_indicators {
    my $class=shift;
    my @kwalitee_indicators;
    foreach my $generator (@{$class->available_generators}) {
	next unless $generator->kwalitee_definitions;
	foreach my $kw (@{$generator->kwalitee_definitions}) {
	    $kw->{defined_in}=$generator;
	    push(@kwalitee_indicators,$kw);
	}
    }
    return \@kwalitee_indicators;
}


sub determine_kwalitee {
    my $class=shift;
    my $type=shift;
    my $metric=shift;
#    print $metric->{dist}."\n" unless $class->conf->quiet;

    my $indicators=$class->kwalitee_indicators;

    foreach my $ind (@$indicators) {
	next unless $ind->{type} eq $type;
	my $code=$ind->{code};
	my $name=$ind->{name};
	my $rv=&$code($metric);

	if ($rv == -1) {
	    $metric->{kwalitee}={kwalitee=>0};
	    foreach (@$indicators) {
		$metric->{kwalitee}{$name}=0;
	    }
	    last;
	} elsif ($rv) {
	    $metric->{kwalitee}{$name}=1;

	    next if $rv<1;
	    $metric->{kwalitee}{kwalitee}+=1;

	} else {
#	    print "+ failed $name\n" if $class->conf->verbose;
	    $metric->{kwalitee}{$name}=0;
	}
    }
#    print "+ Kwalitee: ".$metric->{kwalitee}{kwalitee}."\n" if $class->conf->verbose;
    return;
}



sub yaml2db {
    my $class=shift;
    my $metric=shift;
    my $DBH=$class->DBH;
    my $dist=$metric->{dist};
    my (@keys,@vals,@other_tables);

    while (my ($k,$v)=each %$metric) {
	my $ref=ref($v);
	if (!$ref || $ref eq 'STRING') {
	    push(@keys,$k);
	    push(@vals,$v);
	} elsif ($ref eq 'ARRAY') {
	    # might be list to stringify or data for another table
	    my $first=$v->[0];
	    next unless $first;
	    if (ref($first) eq 'HASH') {
		foreach my $sv (@$v) {
		    my @columns=('distid','dist');
		    my @data=('DISTID',$dist);
		    foreach my $sk (keys %$sv) {
			push(@columns,$sk);
			my $val=$sv->{$sk};
			push(@data,$val);
		    }
		    my $sql="insert into $k (".join(',',@columns).") values (".join(',',map{"'$_'"}@data).")";
		    push(@other_tables,$sql);
		}
	    } else {
		push(@keys,$k);
		push(@vals,join(',',@$v));
	    }
	} elsif ($ref eq 'HASH') {
	    my @columns=('distid','dist');
	    my @data=('DISTID',$dist);
	    foreach my $sk (keys %$v) {
		push(@columns,$sk);
		my $val=$v->{$sk};
		$val=join(',',@$val) if (ref($val) eq 'ARRAY');
		push(@data,$val);
	    }
	    my $sql="insert into $k (".join(',',@columns).") values (".join(',',map{"'$_'"}@data).")";
	    push(@other_tables,$sql);
	}
    }
    # insert into dist
    $DBH->do("insert into dist (".join(',',@keys).") values (".join(',',map{'?'}@vals).")",undef,@vals);
    my $id=$DBH->func('last_insert_rowid');

    foreach my $sql (@other_tables) {
	$sql=~s/DISTID/$id/;
	$DBH->do($sql);
    }

    return;
}


sub create_kwalitee_table {
    my $class=shift;

    my @sql_kw="
create table kwalitee (
   id integer primary key,
   distid integer,
   dist text,
   
   kwalitee integer";

    foreach my $kw (@{$class->kwalitee_indicators}) {
	push(@sql_kw,"   ".$kw->{name}." integer");
    }
    return (join(",\n",@sql_kw)."\n)");
}



1;

__END__

=pod

=head1 NAME

Module::CPANTS::Generator - Generate CPANTS statistics

=head1 SYNOPSIS

See cpants/*.pl for some scripts

=head1 DESCRIPTION

C<Module::CPANTS::Generator> is BETA code, so things might change
in future releases.

more docs to follow.

To generate CPANTS data, run the scripts in the F<cpants> dir included
in the distribution in the following order:

=over

=item 1.

fetch_cpan.pl

=item 2.

analyse_dists.pl

=item 3.

calc_basic_kwalitee.pl

=item 4.

yaml2sqlite.pl

=item 5.

calc_complex_kwalitee.pl

=back

=head1 CPANTS

The CPAN Testing Service.

CPANTS Results can be viewed here:

http://cpants.dev.zsi.at/

Here are various sources for more information:

=over

=item *

Slides of Schwern's talk at YAPC::Europe::2001

http://www.pobox.com/~schwern/talks/CPANTS/full_slides/

=item *

Slides of my talk given at a Vienna.pm Techmeet in September 2003

http://domm.zsi.at/talks/vienna_pm200309/

=item *

Paper for the Proceedings of YAPC::Europe::2003

http://cpants.dev.zsi.at/cpants_paper.html

=back

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

Please use the perl-qa mailing list for discussing all things CPANTS:
http://lists.perl.org/showlist.cgi?name=perl-qa

based on work by Leon Brocard <acme@astray.com> and the original idea
proposed by Michael G. Schwern <schwern@pobox.com>

=head1 LICENSE

Module::CPANTS::Generator is Copyright (c) 2003,2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
