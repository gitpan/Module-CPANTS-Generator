package Module::CPANTS::Generator::Prereq;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Spec::Functions qw(catfile);
use YAML qw(:all);
use Module::MakefilePL::Parse;

use vars qw($VERSION);
$VERSION = "0.21";

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $files=$cpants->files;
    my $testdir=$cpants->testdir;

    my $prereq;
    if (grep {/^META\.yml$/} @$files) {
	my $yaml;
	eval {
	    $yaml=LoadFile(catfile($testdir,'META.yml'));
	};
	if ($yaml) {
	    if ($yaml->{requires}) {
		$prereq=$yaml->{requires};
		store_prereq($cpants,$prereq);
		return;
	    }
	}
    }

    if (grep {/^Build\.PL$/} @$files) {
	$prereq=parse_prereq($cpants,'Build.PL');
	if ($prereq) {
	    store_prereq($cpants,$prereq);
	    return;
	}
    }

    if (grep {/^Makefile\.PL$/} @$files) {
	my $prereq;
	eval {
	    open(my $fh,catfile($cpants->testdir,'Makefile.PL'));
	    # hier kommt manchmal Warnungen:
	    # Warning: possible variable references at /home/domm/perl/Module-CPANTS-Generator/cpants/../lib/Module/CPANTS/Generator/Prereq.pm line 49
	    # oder
	    # Argument "v1.20.3" isn't numeric in addition (+) at /usr/local/share/perl/5.8.3/Module/MakefilePL/Parse.pm line 74, <$fh> line 14.
	    # Bareword "Glib::" refers to nonexistent package at (eval 2550) line 1, <$fh> line 153.

	    my $parser=Module::MakefilePL::Parse->new(join("",<$fh>));
	    $prereq=$parser->required;
	};
	if ($prereq) {
	    store_prereq($cpants,$prereq);
	    return;
	}
    }
    return;
}

sub store_prereq {
    my $cpants=shift;
    my $prereq=shift;

    my @prereq;
    while (my ($module,$version)=each%$prereq) {
	push(@prereq,{
		      requires=>$module,
		      version=>$version,
		     });
    }

    $cpants->{metric}{prereq}=\@prereq;
}


sub parse_prereq {
    my $cpants=shift;
    my $file=shift;

    open(IN,catfile($cpants->testdir,$file)) || return;
    my $m = join '', <IN>;
    close IN;

    my $p;
    if ($file eq 'Makefile.PL') {
	$p = $1 if $m =~ m/PREREQ_PM.*?=>.*?\{(.*?)\}/s;
    } elsif ($file eq 'Build.PL') {
	$p = $1 if $m =~ m/requires.*?=>.*?\{(.*?)\}/s;
    }
    return unless $p;

    # get rid of lines which are only comments
    $p = join "\n", grep { $_ !~ /^\s*#/ } split "\n", $p;
    # get rid of empty lines
    $p = join "\n", grep { $_ !~ /^\s*$/ } split "\n", $p;

    if ($p =~ /=>/ or $p =~ /,/) {
	my $prereqs;

	my $code = "{no strict; \$prereqs = { $p\n}}";
	eval $code;
	return $prereqs;
    }
}

##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions
  ([
    {
     name=>'is_prereq',
     type=>'complex',
     error=>q{This distribution is only required by 2 or less other distributions.},
     code=>sub {
	 my $metric=shift;
	 my $DBH=Module::CPANTS::Generator->DBH;

	 my $module_name=$metric->{distribution}{dist_without_version};
	 return 0 unless $module_name;
	 $module_name=~s/-/::/g;

	 my $required_by=$DBH->selectrow_array("select count(dist) from prereq where requires=?",undef,$module_name);

	 if ($required_by>2) {
	     $DBH->do("update kwalitee set kwalitee=?,is_prereq=1 where dist=?",undef,$metric->{kwalitee}{kwalitee}+1,$metric->{dist}) || die "foo $!";
	     return 1;
	 }
	 return 0;
     },
    },
   ]);


##################################################################
# DB
##################################################################

sub create_db {
    return
[
"create table prereq (
  dist varchar(150),
  requires varchar(150),
  version varchar(25)
)",
"CREATE INDEX prereq_dist_idx on prereq (dist)"
];
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Prereq - parse PREREQ_PM and requires (Build.PL)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

based on work by Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Module::CPANTS::Metrics is Copyright (c) 2003,2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut

