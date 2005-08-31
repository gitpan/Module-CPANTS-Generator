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
use Module::CPANTS::Config;

use vars qw($VERSION);
$VERSION = "0.40";


##################################################################
# SETUP - on load
##################################################################

__PACKAGE__->mk_accessors(qw(quiet generators config opts));


##################################################################
# Class Methods
##################################################################

sub new {
    my $class=shift;
    my $opts=shift || {};
    
    my $cpants=bless {},$class;
    $cpants->config(Module::CPANTS::Config->new());
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
    my $p=Parse::CPAN::Packages->new($self->config->minicpan_02packages($self));
    
    my %seen;
    my $all=Module::CPANTS::DB::Dist->retrieve_all;
    while (my $d=$all->next) {
        $seen{$d->package}++;
    }
    my $now=localtime;
    
    foreach my $dist (sort {$a->dist cmp $b->dist} $p->latest_distributions) {
        my $package=$dist->filename;
        if ($package=~m|/|) {
            $package=~s|^.*/||;
        }

        next if $seen{$package};
        next if $package=~/^perl[-\d]/;
        next if $package=~/^ponie-/;
        next if $package=~/^parrot-/;
        next if $package=~/^Bundle-/;
 
        my $capture=IO::Capture::Stderr->new();
        $capture->start;
   
        my $from=$self->config->minicpan_path_to_dist($dist->prefix);
        my $to=catfile($self->config->testdir,$package);

        if (-e $from) {
            print "$package\n" unless $self->quiet;
            copy ($from,$to) || warn "cannot copy $from to $to: $!";
        } else {
            warn "missing in mirror: $package\n" unless $self->quiet;
            next;
        }
        
        my $dist=Module::CPANTS::DB::Dist->create({
            package=>$package,
            generated_at=>$now,
            generated_with=>$VERSION,
            testfile=>$to,
            from=>$from
        });
        
        foreach my $gen (@{$self->generators}) {
            last unless $gen->analyse($dist);
        }
        
        eval {$dist->update};
        warn $@ if $@;
        
        # remove testing dir
        #   it's easier to delete the whole thing, as certain dist
        #   put their content everywhere...
        rmtree($self->config->testdir);
        
        # create new testing dir for next test
        mkdir($self->config->testdir);
        
        $capture->stop;
        my @errors=$capture->read;
        if (@errors) {
            $dist->cpants_errors(join("\n",@errors));
            print "ERROR: ",@errors,"\n";
            $dist->update;
        }
        
        if ($limit) {
            $cnt++;
            last if $cnt>$limit;
        }
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
