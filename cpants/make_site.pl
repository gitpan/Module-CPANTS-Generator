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

my $version=$Module::CPANTS::Generator::VERSION;
my $now=DateTime->now->strftime("%Y_%V");
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
        date=>DateTime->now,
    },
    'index.html');

# kwalitee
$tt->process(
    'kwalitee',
    {
        kwalitee=>$k,
        total=>scalar @$k,
    },
    'kwalitee.html'
);

# highscores
{
    my $sth_more5=$DBH->prepare("select cpanid,author,average_kwalitee,distcount from authors where distcount>5 order by average_kwalitee desc,distcount desc limit 20");
    $sth_more5->execute;

    my $sth_less5=$DBH->prepare("select cpanid,author,average_kwalitee,distcount from authors where distcount<=5 AND distcount>1 order by average_kwalitee desc,distcount desc limit 20");
    $sth_less5->execute;

    my $sth_best=$DBH->prepare("select dist.dist,dist.author,kwalitee.kwalitee from dist,kwalitee where dist.id=kwalitee.distid AND kwalitee.kwalitee>=? order by kwalitee desc,dist");
    $sth_best->execute($k_total-1);
    
    my $sth_worst=$DBH->prepare("select dist.dist,dist.author,kwalitee.kwalitee from dist,kwalitee where dist.id=kwalitee.distid AND kwalitee < 6 order by kwalitee,dist");
    $sth_worst->execute;
    
    $tt->process(
        'highscores',
        {
            total=>$k_total,
            average=>$k_avg,
            more5=>$sth_more5,
            less5=>$sth_less5,
            best=>$sth_best,
            worst=>$sth_worst,
        },
        'highscores.html',
    );
}

# dists by shortcoming
{
    foreach my $kw (@$k) {
        my $data=$DBH->selectall_arrayref("select dist.dist from dist,kwalitee where kwalitee.distid=dist.id AND kwalitee.".$kw->{name}." = 0 order by dist");
        
        $tt->process(
            'shortcomings',
            {
                count=>scalar @$data,
                list=>$data,
                shortcoming=>$kw,
            },
            "shortcomings_".$kw->{name}.".html",
        );
    }
}
    
# depracated: average kwalitee
if (1==2) {
    open (AVG,">/site/htdocs/average_kwalitee");
    print AVG $k_avg;
    close AVG;
    {
        my (%avgs);
        opendir(DIR,'site/htdocs');
        while (my $f=readdir(DIR)) {
            next unless $f=~/(\d\d\d\d_\d\d)_average/;
            my $date=$1;
            open(IN,"site/htdocs/$f");
            my $davg=<IN>;
            chomp($davg);
            close IN;
            $avgs{$date}=$davg;
        }
        my @x=sort keys %avgs;
        my @y=map {$avgs{$_}} sort keys %avgs;
    
        my $graph=GD::Graph::bars->new(400,400);
        $graph->set(
            x_label=>'Date',
            'y_label'=>'Kwalitee',
            title=>'Average Kwalitee',
            'y_max_value'=>$k_total,
            @bar_defaults,
            );
    
        my $gd=$graph->plot([\@x,\@y]) || die $graph->error;
        open(IMG, ">site/htdocs/average_kwalitee.png") or die $!;
        binmode IMG;
        print IMG $gd->png;

        $tt->process('foo',{
            title=>'Average Kwalitee',
            img=>'average_kwalitee.png',
        },'average_kwalitee.html');
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
    {data=>\@data},
    'graphs.html',
);

