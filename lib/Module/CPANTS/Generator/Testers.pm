package Module::CPANTS::Generator::Testers;
use strict;
use Carp;
use DB_File;
use Net::NNTP;
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';

use vars qw($VERSION);
$VERSION = "0.004";

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

  $self->download unless -f "testers.db";
  tie my %testers,  'DB_File', "testers.db" || die;

  my $cpants = $self->grab_cpants;

  foreach my $dist (keys %$cpants) {
    delete $cpants->{$dist}->{testers};
  }

  while (my($id, $subject) = each %testers) {
    my($action, $dist, $platform) = split /\s/, $subject;
    next unless $action =~ /PASS|FAIL/;

    my @files = glob($dist . "*");
    next unless @files == 1;
    $dist = $files[0];
    $cpants->{$dist}->{testers}->{lc $action}++;
  }

  $self->save_cpants($cpants);
}

1;
