package Module::CPANTS::Generator::Testers;
use strict;
use Carp;
use Cwd;
use DB_File;
use Net::NNTP;
use Storable;

use vars qw($VERSION);
$VERSION = "0.002";

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

sub directory {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{DIR} = $dir;
  } else {
    return $self->{DIR};
  }
}

sub download {
  my $self = shift;

  my $t = tie my %testers,  'DB_File', "testers.db";

  my $nntp = Net::NNTP->new("nntp.perl.org") || die;
  my($num, $first, $last) = $nntp->group("perl.cpan.testers");

  warn "$num: $first-$last\n";

  my $step = 100;

  while (1) {
    last if $first > $last;
    my $next = $first + $step;
    my $h = $nntp->xhdr("subject", "$first-$next");
    foreach my $id (sort keys %$h) {
      my $subject = $h->{$id};
      $testers{$id} = $subject;
      print "$id: $subject\n";
    }
    $t->sync;
    $first += $step;
  }
}

sub generate {
  my $self = shift;

  my $cpants = {};
  eval {
    $cpants = retrieve("cpants.store");
  };
  # warn $@ if $@;

  $self->download unless -f "testers.db";
  tie my %testers,  'DB_File', "testers.db" || die;

  my $origdir = cwd;

  my $dir = $self->directory || croak("No directory specified");
  chdir $dir || croak("Could not chdir into $dir");

  while (my($id, $subject) = each %testers) {
    my($action, $dist, $platform) = split /\s/, $subject;
    next unless $action =~ /PASS|FAIL/;

    my @files = glob($dist . "*");
    next unless @files == 1;
    $dist = $files[0];
    $cpants->{$dist}->{testers}->{lc $action}++;
  }

  chdir $origdir;
  store($cpants, "cpants.store");
}
