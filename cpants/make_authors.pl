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
use CPANPLUS::Backend;

print "make_authors.pl\n".('#'x66)."\n";

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
  author text,
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


my $sth_avg_kwalitee=$DBH->prepare_cached("select avg(kwalitee.kwalitee),count(dist.author) from kwalitee,dist where dist.id=kwalitee.distid AND dist.author=? group by dist.author");
my $sth_insert_auth=$DBH->prepare_cached("insert into authors (cpanid,author,email,average_kwalitee,distcount) values (?,?,?,?,?)");

foreach my $author (sort {$a->cpanid cmp $b->cpanid} values %{$cp->author_tree}) {
    print $author->cpanid,"\n";
    next unless $author->cpanid;
    $sth_avg_kwalitee->execute($author->cpanid);

    my ($avg,$cnt)=(0,0);
    if (my @avg=$sth_avg_kwalitee->fetchrow_array) {
        $avg=$avg[0];
        $cnt=$avg[1];
    }
    $sth_insert_auth->execute($author->cpanid,$author->author,$author->email,$avg,$cnt);
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
