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
use YAML qw(:all);
use File::Spec::Functions qw(catfile);
use Module::CPANTS::Generator;
use IO::Capture::Stderr;

my $class="Module::CPANTS::Generator";
$class->setup_dirs;
$class->load_generators;

print "analyse_dists.pl\n".('#'x66)."\n";

opendir(DIR,$class->distsdir) || die "$!";
my @files=grep {!/^\./} readdir(DIR);

# list of all active dists
my $distfile=catfile($class->distsdir,'dists.yml');
my $dists;
if (-e $distfile) {
    $dists=LoadFile($distfile);
}
my %errors;

# get list of metrics, some might be outdated
my %old_metrics;
opendir(MET,$class->metricdir) || die "cannot open metricsdir ".$class->metricdir.": $!";
while (my $f=readdir(MET)) {
    chomp($f);
    next if $f=~/^\./;
    next if $f eq 'README';
    next if $f eq 'dists.yml';
    $old_metrics{$f}=1;
}

my $cpants_version=$Module::CPANTS::Generator::VERSION;
my $id=1;

foreach my $f (sort keys %$dists) {
    my $status=$dists->{$f};
    next if $f=~/^\./;
    chomp($f);

    unless (-e catfile($class->distsdir,$f)) {
        #    print "dist not in distdir: $f\n";
        next;
    };

    my $cpants=$class->new($f);
    my $metricfile=$cpants->metricfile;
    delete $old_metrics{$cpants->dist.'.yml'};

    print "analyse ".$cpants->package."\n";

    if ($status eq 'old' && -e $metricfile && !$cpants->conf->force) {
        my $oldmetric=$class->read_yaml($metricfile);
        my $generated_with=$oldmetric->{generated_with};
        $generated_with=~s/[^\.\d]//g;
        if ($generated_with eq $cpants_version) {
            print "\tup to date, skip\n";
            next;
        }
	unlink($metricfile);

    } elsif ($status eq 'del') {
        print "\tnot on CPAN anymore, delete\n";
        unlink($metricfile);
        next;
    }

    my $capture = IO::Capture::Stderr->new();
    $capture->start();   
    
    foreach my $generator (@{$cpants->available_generators}) {
        #print "\t+ $generator\n";
        $generator->analyse($cpants);
        last if $cpants->abort;
    }
    $capture->stop;
    my $err=join('',$capture->read);
    if ($err) {
        print $err;
        $errors{$f}=$err;
    }
    
    $cpants->{metric}{id}=$id;
    $cpants->{metric}{cpants_errors}=$err;
    $id++;

    $cpants->write_metric;
    $cpants->tidytemp;
}


# delete old metrics
foreach my $del (keys %old_metrics) {
    print "$del\n\tnot on CPAN anymore, delete\n";
    unlink(catfile($class->metricdir,$del));
}

# write errors
DumpFile(catfile($FindBin::Bin,'errors.yaml'),\%errors);

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
