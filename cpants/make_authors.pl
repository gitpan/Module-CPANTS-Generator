#!/usr/bin/perl -w

#-----------------------------------------------------------------
# make_authors.pl
# Collect condensed infos about CPAN authors
#
# Sixth script to run during CPANTS
#-----------------------------------------------------------------

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator;
use DBI;
use Term::ProgressBar ;
use CPANPLUS::Backend;

my $cpants='Module::CPANTS::Generator';

my $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");
$cpants->DBH($DBH);


#-----------------------------------------------------------------
# create table
#-----------------------------------------------------------------
foreach my $sql((
"create table authors (
  id integer primary key,
  cpanid text,
  name text,
  email text,
  average_kwalitee integer,
  distcount integer
)",
"CREATE INDEX authors_cpanid_idx on authors (cpanid)",)
		) {
    $DBH->do($sql);
}

#-----------------------------------------------------------------
# save CPAN authors in DB
#-----------------------------------------------------------------

my $cp=$cpants->get_cpan_backend;

my $progress=Term::ProgressBar->new({
				     name=>'create authors  ',
				     count=>scalar keys %{$cp->author_tree},
				    }) unless $cpants->conf->no_bar;

my $sth_avg_kwalitee=$DBH->prepare_cached("select avg(kwalitee.kwalitee),count(dist.author) from kwalitee,dist where dist.id=kwalitee.distid AND dist.author=? group by dist.author");
my $sth_insert_auth=$DBH->prepare_cached("insert into authors (cpanid,name,email,average_kwalitee,distcount) values (?,?,?,?,?)");

foreach my $a (values %{$cp->author_tree}) {
    print $a->cpanid,"\n" if $cpants->conf->no_bar;
    next unless $a->cpanid;
    $sth_avg_kwalitee->execute($a->cpanid);

    my ($avg,$cnt)=(0,0);
    if (my @avg=$sth_avg_kwalitee->fetchrow_array) {
	$avg=$avg[0];
	$cnt=$avg[1];

    }
    $sth_insert_auth->execute($a->cpanid,$a->name,$a->email,$avg,$cnt);
    $progress->update() unless $cpants->conf->no_bar;
}

__END__

=pod

=head1 NAME

make_authors.pl -  Collect condensed infos about CPAN authors

=head1 DESCRIPTION

Dump the authors_tree provided by CPANPLUS to the SQLite db.

Add some condensed statistics for each author (avergage kwalitee,
total number of distributions)

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

cpants.pl is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.
