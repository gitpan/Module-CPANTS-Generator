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
    move('cpants.db','cpants_'.DateTime->now->ymd.'.db');
}
my $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");
$cpants->DBH($DBH);

# create dist table and var tables from CPANTS::Generators
{
    my $flds;
    my @other_tables;
    foreach my $generator (@{$cpants->available_generators}) {
	$flds.=$generator->sql_fields_dist if $generator->can('sql_fields_dist');
	push(@other_tables,@{$generator->sql_other_tables}) if $generator->can('sql_other_tables');
    }
    # cleanup flds
    $flds=~s/,\s+$//;

    $DBH->do("
create table dist (id integer primary key,
generated_at text,
generated_with,
$flds
)");

    foreach (@other_tables) {
	$DBH->do($_);
    }

}

# create kwalitee table
{
    my $sql=$cpants->create_kwalitee_table;
    $DBH->do($sql);
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
