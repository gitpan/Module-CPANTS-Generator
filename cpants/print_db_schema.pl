#!/usr/bin/perl -w

#-----------------------------------------------------------------
# db_schema.pl
# Print out the DB schema
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
$cpants->load_generators;

foreach (@{$cpants->get_db_schema}) {
    print "$_\n";
}


__END__

=pod

=head1 NAME

print_db_schema.pl - Print out the CPANTS DB schema

=head1 DESCRIPTION

Prints out the exact database schema used by the current version of
CPANTS.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

CPANTS is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
