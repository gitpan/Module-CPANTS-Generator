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

# fetch all dists from CPAN and store in packed

# TODO: remove all dists in distsdir that aren't current

my $cpants='Module::CPANTS::Generator';

$cpants->setup_dirs;
my $cp=$cpants->get_cpan_backend;

# reload CPAN indices
if ($cpants->conf->reload_cpan) {
    print "+ reload CPAN indices\n" if $cpants->conf->verbose;
    $cp->reload_indices(update_source => 1);
}

my $progress=Term::ProgressBar->new({
				     name=>'Fetch from CPAN ',
				     count=>scalar keys %{$cp->module_tree},
				    });

my %seen;
foreach my $module (sort { $a->module cmp $b->module } values %{$cp->module_tree}) {
    my $package=$module->package;

    $progress->update();

    next if $seen{$package}++;   # allready seen
    next if $package=~/^perl[-\d]/;
    next if $package=~/^ponie-/;
    next if $package=~/^parrot-/;

    $module->fetch(fetchdir=>$cpants->distsdir);
#    print "$package\n";

    if (my $limit=$cpants->conf->limit) {
	last if scalar keys %seen > $limit;
    }
}


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
