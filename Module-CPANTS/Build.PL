use Module::Build;
use strict;

my $build = Module::Build->new(
  module_name => 'Module::CPANTS',
  license     => 'perl',
  requires    => {
    'Test::More' => '0.01',
    'CPANPLUS'   => '0.042',
  },
);
$build->create_build_script;
