#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec::Functions;
use Storable;
use YAML;
use lib "$FindBin::Bin/../lib";

my $arg = shift || die "Pass a string to search for";

my $cpants = retrieve (catfile "$FindBin::Bin/../", "cpants.store")
  || die "Unable to find data";

foreach my $dist (sort keys %$cpants) {
  next unless $dist =~ /$arg/;
  print Dump({ $dist => $cpants->{$dist}});
  print "\n";
}

