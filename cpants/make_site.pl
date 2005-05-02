#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use DBI;
use GD::Graph;
use GD::Graph::bars;
use DateTime;
use File::Copy;
use Module::CPANTS::Generator;
use Template;
use DateTime;
use YAML qw(DumpFile LoadFile);

my $version=$Module::CPANTS::Generator::VERSION;
my $now=DateTime->now;
my $tt=Template->new({
			INCLUDE_PATH=>'site/templates',
			OUTPUT_PATH=>'site/htdocs',
            WRAPPER=>'wrapper',
});

my @bar_defaults=(
		  bar_spacing     => 8,
		  shadow_depth    => 4,
		  shadowclr       => 'dred',
		  transparent     => 0,
		  show_values=>1,
		 );

copy('cpants.db',"site/htdocs/cpants.db");
unlink("site/htdocs/cpants.db.bz2");
system("bzip2 -k site/htdocs/cpants.db");

my $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");

Module::CPANTS::Generator->load_generators;
my $k=Module::CPANTS::Generator->kwalitee_indicators;
my $k_total=@$k;
my $k_avg=$DBH->selectrow_array("select avg(kwalitee) from kwalitee");

# index
$tt->process('index',{
        version=>$version,
        date=>$now,
    },
    'index.html');

# kwalitee
$tt->process(
    'kwalitee',
    {
        kwalitee=>$k,
        total=>scalar @$k,
        version=>$version,
        date=>$now,

    },
    'kwalitee.html'
);

# highscores
{
    my $sth_more5=$DBH->prepare("select cpanid,author,average_kwalitee,distcount from authors where distcount>5 order by average_kwalitee desc,distcount desc");
    $sth_more5->execute;
    my $more5=make_list($sth_more5,'more5');
    my @more5_shortlist=@$more5[0..19];
    
    my $sth_less5=$DBH->prepare("select cpanid,author,average_kwalitee,distcount from authors where distcount<=5 AND distcount>1 order by average_kwalitee desc,distcount desc");
    $sth_less5->execute;
    my $less5=make_list($sth_less5,'less5');
    my @less5_shortlist=@$less5[0..19];
    
    my $sth_best=$DBH->prepare("select dist.dist,dist.author,kwalitee.kwalitee from dist,kwalitee where dist.dist=kwalitee.dist AND kwalitee.kwalitee>=? order by kwalitee.kwalitee desc,dist.dist");
    $sth_best->execute($k_total);
   
    my $sth_worst=$DBH->prepare("select dist.dist,dist.author,kwalitee.kwalitee from dist,kwalitee where dist.dist=kwalitee.dist AND kwalitee < 6 order by kwalitee.kwalitee,dist.dist");
    $sth_worst->execute;
    
    $tt->process(
        'highscores',
        {
            total=>$k_total,
            average=>$k_avg,
            more5=>\@more5_shortlist,
            less5=>\@less5_shortlist,
            best=>$sth_best,
            worst=>$sth_worst,
            version=>$version,
            date=>$now,
        },
        'highscores.html',
    ) || die $tt->error;

    $tt->process(
        'highscores_list',
        {highscores=>$more5,
         title=>'All Authors with more than 5 dists',
        version=>$version,
        date=>$now,
        },
        'authors_more5.html'
    ) || die $tt->error;
    
    $tt->process(
        'highscores_list',
        {
            highscores=>$less5,
            title=>'All Authors with 5 or less dists',
            version=>$version,
            date=>$now,
        },
        'authors_less5.html'
    ) || die $tt->error;
 

}

sub make_list {
    my $sth=shift;
    my $type=shift;
    my $yaml="site/htdocs/$type.yaml";
    my @done;
    my %by_a;
    my $old=LoadFile($yaml);
    my $pos=0;my $cnt=0;my $k=0;
    while (my @r=$sth->fetchrow_array) {
        $cnt++;
        if ($k!=$r[2]) {
            $k=$r[2];
            $pos=$cnt;
        }
        my $prev=$old->{$r[0]};
        my $img;
        if (!$prev) {
            $img='new';
        } else {
            $img='down' if $prev > $r[2];
            $img='up' if $prev < $r[2];
        }
        push(@r,$pos,$prev,$img);
        push(@done,\@r);
        $by_a{$r[0]}=$r[2];
    }
    DumpFile($yaml,\%by_a);
    return \@done;
}

# DB schema
{
    my $schema;
    foreach (@{Module::CPANTS::Generator->get_db_schema}) {
        $schema.="$_\n";
    }
    
    $tt->process(
        'db_schema',
        {
            schema=>$schema,
            version=>$version,
            date=>$now,
        },
        'db_schema.html'
    ) || die $tt->error;

}


# dists by shortcoming
{
    foreach my $kw (@$k) {
        my $data=$DBH->selectall_arrayref("select * from kwalitee where kwalitee.".$kw->{name}." = 0 order by dist");
        
        $tt->process(
            'shortcomings',
            {
                count=>scalar @$data,
                list=>$data,
                shortcoming=>$kw,
                version=>$version,
                date=>$now,
            },
            "shortcomings_".$kw->{name}.".html",
        );
    }
}

# author pages
print "authors\n";

{
    my $sth=$DBH->prepare('select cpanid,average_kwalitee,distcount from authors order by cpanid');
    $sth->execute;
    while (my $r=$sth->fetchrow_hashref) {
        my $dists=$DBH->selectall_arrayref('select kwalitee.dist,kwalitee.kwalitee from kwalitee,dist where dist.dist=kwalitee.dist AND dist.author=?',undef,$r->{cpanid});
        #print $r->{cpanid},"\n";
        $tt->process(
            'author',
            {
                author=>$r,
                dists=>$dists,
                version=>$version,
                date=>$now,
                topdir=>'../',
            },
            'authors/'.$r->{cpanid}.".html",
        );

        DumpFile('site/htdocs/authors/'.$r->{cpanid}.'.yml',
            {
                cpanid=>$r->{cpanid},
                author=>$r->{author},
                average_kwalitee=>$r->{average_kwalitee},
                distcount=>$r->{distcount},
                dists=>$dists,
            }
        );
    }
}


# graphs
my @data;
foreach
  (
   {
    title=>'Kwalitee Distribution',
    sql=>'select kwalitee,count(kwalitee) as cnt from kwalitee group by kwalitee order by kwalitee',
    lablex=>'Kwalitee',
    labley=>'Distributions',
    text=>'Distribution of Kwalitee ratings.',
   },
   {
    title=>'Active CPAN IDs',
    sql=>['select "not active",count(*) from authors where distcount=0',
	  'select "active",count(*) from authors where distcount>0',
	  ],
    lablex=>'Status',
    labley=>'Authors',
    text=>'Of all people with CPAN IDs, how many actually uploaded a dist to CPAN.',
   },

   {
    title=>'Dists per Author',
    sql=>'select distcount,count(distcount) as cnt from authors where distcount > 0 group by distcount order by distcount',
    lablex=>'Dists',
    labley=>'Authors',
    text=>'Number of Dists for a given author',
    width=>800,
   },
   {
    title=>'Year of release',
    sql=>'select substr(released_date,-4,4) as year,count(substr(released_date,-4,4)) from dist group by year order by year',
    lablex=>'Year',
    labley=>'Dists',
    text=>'The number of dists released each year. This is not the year of first release, but the year of the current release on CPAN.',
   },

#   {
#    title=>'',
#    sql=>'',
#    lablex=>'',
#    labley=>'',
#    text=>'',
#   },


  ) {
      generate_item($_);
  }


sub generate_item {
    my $c=shift;

    my $title=$c->{title};
    my $filename=lc($title);
    $filename=~s/ /_/g;
    $filename=~s/\W//g;
    $filename.=".png";

    my (@x,@y);
    my $maxy=0;

    if (ref($c->{sql}) eq 'ARRAY') {
        foreach my $sql (@{$c->{sql}}) {
            my $sth=$DBH->prepare($sql);
            $sth->execute;
            while (my @r=$sth->fetchrow_array) {
                push(@x,shift(@r));
                my $y=shift(@r);
                push(@y,$y);
                $maxy=$y if $y>$maxy;
            }
            $maxy=int($maxy*1.05);
        }
    } else {
        my $sth=$DBH->prepare($c->{sql});
        $sth->execute;

        while (my @r=$sth->fetchrow_array) {
            push(@x,shift(@r));
            my $y=shift(@r);
            push(@y,$y);
            $maxy=$y if $y>$maxy;
        }
        $maxy=int($maxy*1.05);
    }

    my $graph=GD::Graph::bars->new($c->{width} || 400,400);

    $graph->set(
		x_label=>$c->{lablex},
		'y_label'=>$c->{labley},
		title=>$title,
		'y_max_value'=>$maxy,
		@bar_defaults,
    );

    my $gd=$graph->plot([\@x,\@y]);
    return unless $gd;
    open(IMG, ">site/htdocs/$filename") or die $!;
    binmode IMG;
    print IMG $gd->png;

    push(@data,{
		heading=>$title,
		text=>$c->{text},
		img=>$filename,
	       });
}

$tt->process(
    'graphs',
    {
        data=>\@data,
        version=>$version,
        date=>$now,
    },
    'graphs.html',
);

