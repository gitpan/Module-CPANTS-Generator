#!/usr/bin/perl -w

#-----------------------------------------------------------------
# analyse_dists.pl
# Run all registered analysers on distributions
# Save results as YAML in metrics
#
# Second script to run during CPANTS
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Term::ProgressBar;

use Module::CPANTS::Generator;
my $class="Module::CPANTS::Generator";
$class->setup_dirs;
$class->load_generators;

opendir(DIR,$class->distsdir) || die "$!";
my @files=grep {!/^\./} readdir(DIR);

my $progress=Term::ProgressBar->new({
				     name=>'Analyse Dists   ',
				     count=>scalar @files,
				    }) unless $class->conf->no_bar;


foreach my $f (@files) {
    next if $f=~/^\./;
    chomp($f);

    my $cpants=$class->new($f);

    print "\n",$cpants->package,"\n" if $cpants->conf->no_bar;

    foreach my $generator (@{$cpants->available_generators}) {
	print "+ $generator\n" if $cpants->conf->no_bar;
	$generator->analyse($cpants);
	last if $cpants->abort;
    }

    $cpants->write_metric;
    $cpants->tidytemp;

    $progress->update() unless $class->conf->no_bar;
}

__END__

=pod

=head1 NAME

analyse_dists.pl - Run all registered analysers on distributions

=head1 DESCRIPTION

Foreach distribution that's saved in L<distsdir>, run the
L<analyse>-method of all loaded generators.

The results are written to files in YAML format into the directory
F<metrics>

=head2 Configuration / Options

=over

=item distsdir

Directory where fetched packages are stored.

Default: dists

=back

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
