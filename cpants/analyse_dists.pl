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
use YAML qw(:all);
use File::Spec::Functions qw(catfile);

use Module::CPANTS::Generator;
my $class="Module::CPANTS::Generator";
$class->setup_dirs;
$class->load_generators;

opendir(DIR,$class->distsdir) || die "$!";
my @files=grep {!/^\./} readdir(DIR);

# list of all active dists
my $dists=LoadFile('dists.yml');

# get list of metrics, some might be outdated
my %old_metrics;
opendir(MET,$class->metricdir) || die "cannot open metricsdir ".$class->metricdir.": $!";
while (my $f=readdir(MET)) {
    chomp($f);
    next if $f=~/^\./;
    next if $f eq 'README';
    $old_metrics{$f}=1;
}


my $progress=Term::ProgressBar->new({
				     name=>'Analyse Dists   ',
				     count=>scalar keys %$dists,
				    }) unless $class->conf->no_bar;

my $cpants_version=$Module::CPANTS::Generator::VERSION;

my $id=1;

while (my($f,$status)=each(%$dists)) {
    next if $f=~/^\./;
    chomp($f);

    $progress->update() unless $class->conf->no_bar;
    next unless (-e catfile($class->distsdir,$f));

    my $cpants=$class->new($f);
    my $metricfile=$cpants->metricfile;
    delete $old_metrics{$cpants->dist.'.yml'};

    print $cpants->package,"\n" if $cpants->conf->no_bar;

    if ($status eq 'old' && -e $metricfile && !$cpants->conf->force) {
	my $oldmetric=LoadFile($metricfile);
	my $generated_with=$oldmetric->{generated_with};
	$generated_with=~s/[^\.\d]//g;
#	print "generated $generated_with\n";
	next if $generated_with eq $cpants_version;
	unlink($metricfile);

    } elsif ($status eq 'del') {
	unlink($metricfile);
	next;
    }


    foreach my $generator (@{$cpants->available_generators}) {
	print "+ $generator\n" if $cpants->conf->no_bar;
	$generator->analyse($cpants);
	last if $cpants->abort;
    }

    $cpants->{metric}{id}=$id;
    $id++;

    $cpants->write_metric;
    $cpants->tidytemp;
}


# delete old metrics
foreach my $del (keys %old_metrics) {
    print "purge $del\n" if $class->conf->no_bar;
    unlink(catfile($class->metricdir,$del));
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
