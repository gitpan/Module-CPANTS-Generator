#!/usr/bin/perl -w

#-----------------------------------------------------------------
# fetch_cpan.pl
# Fetch all dists from CPAN
#
# First script to run during CPANTS
#-----------------------------------------------------------------
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Module::CPANTS::Generator;
use Carp;
use YAML qw(:all);
use Parse::CPAN::Packages;
use File::Copy;
use File::Spec::Functions;

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
my $limit=$cpants->conf->limit || 0;

print "fetch_cpan.pl\n".('#'x66)."\n" unless $cpants->conf->quiet;

# get list of allready downloaded packages
my %downloaded;
opendir(DISTS,$cpants->distsdir) || die "cannot open distsdir ".$cpants->distsdir.": $!";

while (my $f=readdir(DISTS)) {
    chomp($f);
    next if $f=~/^\./;
    next if $f eq 'README';
    $downloaded{$f}=1;
}

print "parsing 02packages.details.txt.gz ..\n"  unless $cpants->conf->quiet;

my $p = Parse::CPAN::Packages->new("/home/minicpan/modules/02packages.details.txt.gz");
my (%seen,@packages);

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
    
    $seen{$package}='new';

    if ($downloaded{$package}) {
        delete $downloaded{$package};
        #print "skip $package\n" unless $cpants->conf->quiet;
        $seen{$package}='old';
        next;
    }
    
    my $from=catfile("/home/minicpan/authors/id",$dist->prefix);
    if (-e $from) {
        my $to=catfile($cpants->distsdir,$package);
        print "fetch $package\n" unless $cpants->conf->quiet;
        copy ($from,$to) || print "cannot copy $from to $to: $!";
    } else {
        print "missing in mirror: $package\n" unless $cpants->conf->quiet;
    }
    
    if ($limit) {
        last if scalar keys %seen > $limit;
    }
}

# delete old dists
foreach my $del (keys %downloaded) {
    print "purge $del\n" unless $cpants->conf->quiet;
    $seen{$del}='del';
    system("rm",$cpants->distsdir."/".$del);
}

DumpFile(catfile($cpants->distsdir,'dists.yml'),\%seen);


__END__

=pod

=head1 NAME

fetch_cpan.pl - Fetch all dists from CPAN

=head1 DESCRIPTION

Fetch all dists from CPAN. You better use a local CPAN mirror or have
a B<fat> network connection.

Doesn't fetch perl/ponie/parrot distributions.

=head2 Configuration / Options

=over

=item quite

Don't output stuff.

=item cpan

Absolut path to a local CPAN mirror.

Default: /home/minicpan/

=item distsdir

Directory where fetched packages are stored.

Default: dists

=item limit

Limit fetching of packages to supplied number. Mostly usefull during
development of new features.

Default: undef

=back

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
