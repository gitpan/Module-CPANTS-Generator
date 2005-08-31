use strict;
use Module::Build;
use File::Spec::Functions;

my $build = Module::Build->new
  (
   module_name => 'Module::CPANTS::Generator',
   license     => 'perl',
   requires    => {
        'Class::Accessor' => '0.19',
        'Parse::CPAN::Packages'=> '2.24',
        'Module::Pluggable'=> '2.8',
        'CPANPLUS'    => '0.053',
        'CPAN::DistnameInfo'=>'0.05',
        'DBD::SQLite' => '0.31',
        'DBI' => '1.42',
        'Class::DBI' => '0.96',
        'Class::DBI::Pager' => '0.05',
        'IO::Capture' => '0.03',
        'Archive::Any' => '0.06',
        'Pod::Simple' => '3.02',
        'YAML' => '0.36',
        'Module::ExtractUse' => '0.15',
    },
   create_makefile_pl=>'passthrough',
);


$build->create_build_script;

