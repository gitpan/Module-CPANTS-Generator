#!/usr/bin/perl -w

#-----------------------------------------------------------------
# calc_basic_kwalitee.pl
# Calculate Kwalitee
#
# Third script to run during CPANTS
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;
use YAML qw(:all);

print "calc_basic_kwalitee.pl\n".('#'x66)."\n";

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
$cpants->load_generators;

chdir($cpants->metricdir);
opendir(DIR,'.') || die "$!";
my @files=grep {/\.yml$/} readdir(DIR);

foreach my $f (sort @files) {
    chomp($f);
    my $metric=$cpants->read_yaml($f);
    unless ($metric) {
        print "missing metric: $f\n";
        next;
    }
    
    # remove old kwalitee, just to make sure...
    delete($metric->{kwalitee});

    $cpants->determine_kwalitee('basic',$metric);
    $cpants->write_metric($metric,$f);
    print $metric->{kwalitee}{kwalitee}."\t$f\n";
}



__END__

=pod

=head1 NAME

calc_basic_kwalitee.pl - Calculate Kwalitee

=head1 DESCRIPTION

Calculate Kwalitee for each distribution by looking at the YAML metric
files.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
