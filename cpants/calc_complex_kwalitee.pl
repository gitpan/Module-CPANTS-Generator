#!/usr/bin/perl -w

#-----------------------------------------------------------------
# calc_complex_kwalitee.pl
# Calculate complex Kwalitee
#
# Fifth script to run during CPANTS
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;
use YAML qw(:all);
use DBI;

print "calc_complex_kwalitee.pl\n".('#'x66)."\n";

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
$cpants->load_generators;

my $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");
$cpants->DBH($DBH);

chdir(Module::CPANTS::Generator->metricdir);
opendir(DIR,'.') || die "$!";
my @files=grep {/\.yml$/} readdir(DIR);


foreach my $f (sort @files) {
    chomp($f);
    my $metric=$cpants->read_yaml($f);
    unless ($metric) {
        print "missing metric: $f\n";
        next;
    }

    print $f,"\n";

    $cpants->determine_kwalitee('complex',$metric);
    $cpants->write_metric($metric);

}



__END__

=pod

=head1 NAME

calc_complex_kwalitee.pl -  Calculate complex Kwalitee

=head1 DESCRIPTION

Calculate complex Kwalitee for each distribution by looking at various
information (e.g. that's allready in the SQLite DB).

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
