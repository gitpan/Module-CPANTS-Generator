#!/usr/bin/perl -w
use strict;
use CPANPLUS;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;

# get object
my $cpants=Module::CPANTS::Generator->new;

# CPANPLUS
print "Loading CPANPLUS\n" if $cpants->conf->verbose;
my $cp=CPANPLUS::Backend->new(conf => {verbose => 0, debug => 0});

# set local cpan mirror if there is one - RECOMMENDED
if (my $local_cpan=$cpants->conf->cpan) {
    my $cp_conf=$cp->configure_object;
    $cp_conf->_set_ftp(urilist=>
		       [{
			 scheme => 'file',
			 path   => $local_cpan,
			}]);
}

# reload CPAN indices
if ($cpants->conf->reload_cpan) {
    print "+ reload CPAN indices\n" if $cpants->conf->verbose;
    $cp->reload_indices(update_source => 1);
}

# get dist list from DB
my $dbh=Module::CPANTS::Reporter::DB->DBH;
my %seen;
%seen=map {$_->[0]=>1} @{$dbh->selectall_arrayref("select package from cpants")} unless $cpants->conf->force;

# for limiting number of tested packages
my $l=$cpants->conf->limit;
my $cnt=1;

# get all modules from CPAN and run tests
foreach my $module (sort { $a->module cmp $b->module } values %{$cp->module_tree}) {
    my $package=$module->package;
    unless ($package) {
	print "- ".$module->module.".: No package found, skipping\n";
	next;
    }
    next if $seen{$package}++;   # allready seen

    my $metric=$cpants->unpack_cpanplus($module);
    if ($metric->error) { # besser vielleicht $metric->unpack_ok
	$metric->report;
	next;
    }

    # run tests
    chdir($metric->unpacked);
    foreach my $testclass (@{$cpants->tests}) {
	print "\trunning $testclass\n" if $cpants->conf->verbose;
	$testclass->generate($metric);
    }
    $metric->report;

    # limiting
    last if $l && $cnt==$l;
    $cnt++;
}

foreach my $rep (@{$cpants->reporter}) {
    $rep->finish;
}

# TODO: clean up
# delete all dirs in $unpack_dir that are not in %seen


__END__

=pod

=head1 NAME

cpants.pl - run Module::CPANTS::Generator on CPAN

=head1 DESCRIPTION

This script is running Kwalitee tests against all distributions on CPAN.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2003 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
