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
use CPANPLUS;
use Carp;
use Term::ProgressBar;
use YAML qw(:all);

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
my $cp=$cpants->get_cpan_backend;
my $limit=$cpants->conf->limit || 0;

# reload CPAN indices
unless ($cpants->conf->dont_reload_cpan) {
    $cp->reload_indices(update_source => 1);
}

# get list of allready downloaded packages
my %downloaded;
opendir(DISTS,$cpants->distsdir) || die "cannot open distsdir ".$cpants->distsdir.": $!";
while (my $f=readdir(DISTS)) {
    chomp($f);
    next if $f=~/^\./;
    next if $f eq 'README';
    $downloaded{$f}=1;
}


# get list of packages on CPAN
my (%seen,@packages);
foreach my $module (values %{$cp->module_tree}) {
    my $package=$module->package;
    next unless $package;

    # skip some stuff
    next if $package=~/^perl[-\d]/;
    next if $package=~/^ponie-/;
    next if $package=~/^parrot-/;
    next if $package=~/^Bundle-/;

    next if $seen{$package};
    $seen{$package}='new';

    if ($downloaded{$package}) {
	delete $downloaded{$package};
	print "skip $package\n" if $cpants->conf->no_bar;
	$seen{$package}='old';
	next;
    }

    push(@packages,$module);
}

my $progress=Term::ProgressBar->new({
				     name=>'Fetch from CPAN ',
				     count=>$limit || scalar @packages,
				    }) unless $cpants->conf->no_bar;

foreach my $module (@packages) {
    my $package=$module->package;

    $module->fetch(fetchdir=>$cpants->distsdir);
    print "fetch $package\n" if $cpants->conf->no_bar;

    if ($limit) {
	last if scalar keys %seen > $limit;
    }

    $progress->update() unless $cpants->conf->no_bar;
}

# delete old dists
foreach my $del (keys %downloaded) {
    print "purge $del\n" if $cpants->conf->no_bar;
    $seen{$del}='del';
    system("rm",$cpants->distsdir."/".$del);
}


DumpFile('dists.yml',\%seen);

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

=item cpan

Absolut path to a local CPAN mirror.

Default: /home/cpan/

=item  reload_cpan

Reload CPAN indices (see CPANPLUS).

Default: undef

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
