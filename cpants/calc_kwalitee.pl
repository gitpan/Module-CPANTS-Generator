#!/usr/bin/perl
use strict;
use warnings;
 
use lib('../lib/','lib/');

use Module::CPANTS::Generator;

use Module::CPANTS::DB;

my $cpants=Module::CPANTS::Generator->new;


my $dbh=Module::CPANTS::DB->db_Main;


# links dists with uses and prereq
{
    my %mods;
    my $sth=$dbh->prepare("select module,dist from modules");
    $sth->execute;
    while (my($mod,$dist)=$sth->fetchrow_array) {
        $mods{$mod}=$dist;
    }

    while (my($mod,$dist)=each%mods) {
        $dbh->do("update uses set in_dist=? where module=?",undef,$dist,$mod);
        $dbh->do("update prereq set in_dist=? where requires=?",undef,$dist,$mod);
    }
}

$cpants->calc_kwalitee;

# recursive prereqs NOT WORKING
if (1==2){
    my $sth=$dbh->prepare("select prereq.dist,dist.id,dist.dist_without_version from dist,prereq where dist.id=prereq.in_dist order by prereq.dist");
    $sth->execute;
    my $this_dist;
    my %dists;
    while (my ($dist,$oid,$oname)=$sth->fetchrow_array) {
        push(@{$dists{$dist}},[$oid,$oname]);
    }
    while (my ($di,$data) = each(%dists)) {
        my $pre=get_prereq($di,$data);
        print "$di: $pre\n";
    }

my %pre;
sub get_prereq {
    my $di=shift;
    my $data=shift;
    my $pre;
    foreach (@$data) {
        next if $_->[0]==$di;
        next if $di == 135;
        print $_->[0],"\n";
        if (!$pre{$_->[0]}) {
            #my $newpre=get_prereq($_->[0],$dists{$_->[0]});
            my $newpre=$_->[0].",";
            $pre{$_->[0]}=$newpre;
        }
        $pre.=$pre{$_->[0]};
    }
    return $pre; 
}
}

# AUTHOR: num_dists, average
{
    my $sth=$dbh->prepare("select count(*) as num_dists,avg(kwalitee.kwalitee) as average,dist.author as id from dist,kwalitee where dist.kwalitee=kwalitee.id group by author");
    $sth->execute;
    while (my @r=$sth->fetchrow_array) {
        $dbh->do("update author set num_dists=?,average_kwalitee=? where id=?",undef,@r);
    }
    $sth->finish;
    $dbh->do("update author set num_dists=0 where num_dists is null");
}

# RANKS
foreach my $query ("select average_kwalitee,id from author where num_dists>=5 order by average_kwalitee desc",
"select average_kwalitee,id from author where num_dists<5 AND num_dists>0 order by average_kwalitee desc")
    {
    my $sth=$dbh->prepare($query);
    $sth->execute;
    my $pos=0;my $cnt=0;my $k=0;
    my @done;
    while (my ($avg,$id)=$sth->fetchrow_array) {
        $cnt++;
        if ($k!=$avg) {
            $k=$avg;
            $pos=$cnt;
        }
        push(@done,[$pos,$id]);
    }
    foreach (@done) {
        $dbh->do("update author set rank=? where id=?",undef,@$_);
    }
}


