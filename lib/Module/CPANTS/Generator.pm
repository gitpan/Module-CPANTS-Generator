package Module::CPANTS::Generator;
use strict;
use warnings;
use Carp;
use Cwd;
use Data::Dumper;
use base qw(Class::Accessor);

use Parse::CPAN::Packages;
use File::Spec::Functions qw(catdir catfile);
use Module::Pluggable search_path=>['Module::CPANTS::Generator'];
use File::Copy;
use File::Path;
use IO::Capture::Stderr;

use vars qw($VERSION);
$VERSION = "0.43";

##################################################################
# SETUP - on load
##################################################################

__PACKAGE__->mk_accessors(qw(quiet generators opts lint_file));


##################################################################
# Class Methods
##################################################################

sub new {
    my $class=shift;
    my $opts=shift || {};
    
    my $cpants=bless {},$class;
    $cpants->opts($opts);
    
    my %generators;
    foreach my $gen ($cpants->plugins) {
        eval "require $gen";
        croak "cannot load $gen: $@" if $@;
        $generators{$gen}=$gen->order;
        
    }
    my @generators=sort { $generators{$a} <=> $generators{$b} } keys %generators;
    $cpants->generators(\@generators);
    return $cpants;
}

my $cnt=1;
sub analyse_cpan {
    my $self=shift;
    
    my $limit=$self->opts->{'limit'} || 0;
    print "parsing packages info...\n";
    my $p=Parse::CPAN::Packages->new($self->minicpan_02packages($self));
    
    my %seen;
    my $all=Module::CPANTS::DB::Dist->retrieve_all;
    while (my $d=$all->next) {
        $seen{$d->package}++;
    }
    
    $self->set_date;
    foreach my $dist (sort {$a->dist cmp $b->dist} $p->latest_distributions) {
        my $package=$dist->distvname;
        
        next if $seen{$package};
        next if $package=~/^perl[-\d]/;
        next if $package=~/^ponie-/;
        next if $package=~/^Perl6-Pugs/;
        next if $package=~/^parrot-/;
        next if $package=~/^Bundle-/;
        
        print $dist->distvname."\n" unless $self->quiet;
        
        my $file=$self->minicpan_path_to_dist($dist->prefix);
        $self->analyse_dist($file);
        
        if ($limit) {
            $cnt++;
            last if $cnt>$limit;
        }
    }
}
    
sub analyse_dist {
    my $self=shift;
    my $file=shift;
  
    my $capture=IO::Capture::Stderr->new();
    $capture->start;
   
    # remove testing dir
    #   it's easier to delete the whole thing, as certain dist
    #   put their content everywhere...
    rmtree($self->testdir);
        
    # create new testing dir for testing
    mkdir($self->testdir);
    
    if (!-e $file) {
        warn "package not found: $file\n" unless $self->quiet;
        return;
    }
        
    my $dist;
    eval {
        $dist=Module::CPANTS::DB::Dist->create({
                #package=>$package,
                #testfile=>$to,
            from=>$file,
        });
    
        foreach my $gen (@{$self->generators}) {
            last unless $gen->analyse($dist);
        }
        
        $dist->update;
    };
    warn $@ if $@;
        
    $capture->stop;
    my @errors=$capture->read;
    if (@errors) {
        $dist->cpants_errors(join("\n",@errors));
        print "ERROR: ",@errors,"\n";
        $dist->update;
    }
}


sub calc_kwalitee {
    my $self=shift;

    # build up kwalitee generators
    my @indicators=$self->get_indicators;

    my $all=Module::CPANTS::DB::Dist->retrieve_all;
    while (my $dist=$all->next) {
        #next if $dist->kwalitee;
        
        my $kwalitee=0;
        my %k;
        foreach my $ind (@indicators) {
            my $rv=$ind->{code}($dist);
            $k{$ind->{name}}=$rv;
            $kwalitee+=$rv;
        }
        $k{'kwalitee'}=$kwalitee;
        $dist->kwalitee(Module::CPANTS::DB::Kwalitee->create(\%k));
        $dist->update;
        print "$kwalitee\t".$dist->dist."\n";
    }
}

sub get_indicators {
    my $self=shift;
    
    my @indicators;
    foreach my $gen (@{$self->generators}) {
        foreach my $ind (@{$gen->kwalitee_indicators}) {
            $ind->{defined_in}=$gen;
            push(@indicators,$ind); 
        }
    }
    return wantarray ? @indicators : \@indicators;
}

sub get_indicators_hash {
    my $self=shift;

    my %indicators;
    foreach my $gen (@{$self->generators}) {
        foreach my $ind (@{$gen->kwalitee_indicators}) {
            $ind->{defined_in}=$gen;
            $indicators{$ind->{name}}=$ind;
        }
    }
    return \%indicators;
}

sub get_schema {
    my $self=shift;

    my %schema=(
        kwalitee=>['id INTEGER PRIMARY KEY','kwalitee integer not null default 0'],
    );
    foreach my $gen (@{$self->generators}) {
        my $gen_schema=$gen->schema;
        foreach my $table (keys %$gen_schema) {
            $schema{$table}=[] unless $schema{$table};
            push(@{$schema{$table}},@{$gen_schema->{$table}});
        }

        my $kwind=$gen->kwalitee_indicators;
        foreach my $ind (@$kwind) {
            push(@{$schema{'kwalitee'}},$ind->{'name'}." integer not null default 0");       
        }
    }
    return \%schema;
}

sub get_schema_text {
    my $self=shift;
    my $schema=$self->get_schema;
    my $indices=$schema->{'index'};
    delete $schema->{'index'};

    my $dump;
    while (my($table,$columns)=each%$schema) {
       $dump.="create table $table (\n".join(",\n",map {"   $_"}@$columns)."\n);\n\n";
    }
    foreach (@$indices) {
        $dump.="$_;\n";
    }
    return $dump;
}

sub set_date {
    my $self=shift;
    my $version=$VERSION;
    my $now=localtime;
    my $dbh=Module::CPANTS::DB->db_Main;
    $dbh->do("insert into version values (?,?)",undef,$version,$now);
    return;
}



#----------------------------------------------------------------
# CONFIG STUFF
#----------------------------------------------------------------

# currently hardcoded, should be settable via ./Build
sub basedir { '/home/domm/perl/Module-CPANTS-Generator/cpants/' }
sub minicpan { '/home/minicpan/' }

# config values induced from others
sub db_file {
    my $self=shift;
    return catfile($self->basedir,'cpants.db');
}
sub prev_db_file { return catfile(shift->basedir,'cpants_previous.db') }

sub minicpan_01mailrc {
    my $self=shift;
    return catfile($self->minicpan,'authors','01mailrc.txt.gz');
}

sub minicpan_02packages {
    my $self=shift;
    return catfile($self->minicpan,'modules','02packages.'.($self->opts->{'test'}?'cpants_'.$self->opts->{'test'}:'details').'.txt.gz');
}

sub minicpan_path_to_dist {
    my $self=shift;
    my $prefix=shift;
    return catfile($self->minicpan,'authors','id',$prefix);
}

sub testdir {
    return catfile(shift->basedir,'testing','tmp');
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

generate_db.pl

=item 2.

analyse_dists.pl

=item 3.

calc_kwalitee.pl

=item 4.

make_graphs.pl

=back

=head1 CPANTS

The CPAN Testing Service.

CPANTS Results can be viewed here:

http://cpants.perl.org/

Here are various sources for more information:

=over

=item *

Slides of Schwern's talk at YAPC::Europe::2001

http://www.pobox.com/~schwern/talks/CPANTS/full_slides/

=item *

Slides of my talk given at FOSDEM 2005

http://domm.zsi.at/talks/2005_brussels_cpants/

=back

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

Please use the perl-qa mailing list for discussing all things CPANTS:
http://lists.perl.org/showlist.cgi?name=perl-qa

based on work by Leon Brocard <acme@astray.com> and the original idea
proposed by Michael G. Schwern <schwern@pobox.com>

=head1 LICENSE

Module::CPANTS::Generator is Copyright (c) 2003,2004,2005 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
