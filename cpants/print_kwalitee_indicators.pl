#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Module::CPANTS::Generator;
Module::CPANTS::Generator->load_generators;

my $ind=Module::CPANTS::Generator->kwalitee_indicators;

print "Total Kwalitee: ",scalar @$ind,"\n";

print "Indicators: \n";
foreach (@$ind) {
    print "\t",$_->{name},"\n";
}
