#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;

use_ok("Module::CPANTS");

my $cpants = Module::CPANTS->new()->data;
my $data = $cpants->{'Acme-Colour-0.20.tar.gz'};

is($data->{author}, "LBROCARD");
is_deeply($data->{files}, ['Makefile.PL', 'README', 'MANIFEST']);

my $m = $data->{requires_module};
is_deeply($, {
          'List::Util' => 0,
          'Test::Simple' => 0,
          'Graphics::ColorNames' => 0
});

my $r = $data->{requires};
is_deeply($r, [
          'Graphics-ColorNames-0.32.tar.gz',
          'Scalar-List-Utils-1.11.tar.gz',
          'Test-Simple-0.47.tar.gz'
]);

my $rr = $data->{requires_recursive};
is_deeply($rr, [
          'File-Spec-0.82.tar.gz',
          'Graphics-ColorNames-0.32.tar.gz',
          'Scalar-List-Utils-1.11.tar.gz',
          'Test-Harness-2.26.tar.gz',
          'Test-Simple-0.47.tar.gz'
]);

my $testers = $data->{testers};
is_deeply($testers, {
      'fail' => 1,
      'pass' => 5,
});
