#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS;
use YAML;

my $arg = shift || die "Pass a string to search for";

my $cpants = Module::CPANTS->new->data;

foreach my $dist (sort keys %$cpants) {
  next unless $dist =~ /$arg/;
  print Dump({ $dist => $cpants->{$dist}});
  print "\n";
}

