#!/usr/bin/perl -w

#-----------------------------------------------------------------
# yaml2sqlite.pl
# Convert YAML metric files to SQLite DB
#
# Fourth script to run during CPANTS
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;
use YAML qw(:all);
use DBI;
use File::Copy;
use DateTime;
use Term::ProgressBar ;

my $cpants='Module::CPANTS::Generator';
$cpants->setup_dirs;
$cpants->load_generators;

#-----------------------------------------------------------------
# create DB
#-----------------------------------------------------------------
if (-e 'cpants.db') {
    my $mtime=(stat('cpants.db'))[9];
    move('cpants.db','cpants_'.DateTime->from_epoch(epoch=>$mtime)->ymd.'.db');
}
my $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");
$cpants->DBH($DBH);

foreach (@{$cpants->get_db_schema}) {
    $DBH->do($_);
}


#-----------------------------------------------------------------
# save YAML in DB
#-----------------------------------------------------------------
chdir(Module::CPANTS::Generator->metricdir);
opendir(DIR,'.') || die "$!";
my @files=grep {/\.yml$/} readdir(DIR);

my $progress=Term::ProgressBar->new({
				     name=>'yaml2sqlite     ',
				     count=>scalar @files,
				    }) unless $cpants->conf->no_bar;

foreach my $f (@files) {
    chomp($f);
    my $metric=LoadFile($f);
    print $metric->{dist}."\n" if $cpants->conf->no_bar;
    $cpants->yaml2db($metric);
    $progress->update() unless $cpants->conf->no_bar;
}


__END__

=pod

=head1 NAME

yaml2sqlite.pl - Convert YAML metric files to SQLite DB

=head1 DESCRIPTION

Convert the YAML metric files to a SQLite DB.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
