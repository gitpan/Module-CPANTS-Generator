use strict;
use Module::Build;
use File::Spec::Functions;

my $build = Module::Build->new
  (
   module_name => 'Module::CPANTS::Generator',
   license     => 'perl',
   requires    => {
		   'AppConfig'=>'1.56',
		   'Class::Accessor' => '0.19',
		   'Class::Data::Inheritable' => '0.02',
		   'CPANPLUS'    => '0.053',
		   'CPAN::DistnameInfo'=>'0.05',
		   'DBD::SQLite' => '0.31',
		   'DBI' => '1.42',
		   'DateTime' => '0.21',
		   'Module::ExtractUse' => '0.15',
		   'Pod::Strip' => '1.00',
		   'Pod::Simple::Checker' => '2.02',
		   'Storable' => '2.09',
		   'Test::More'  => '0.01',
		   'Term::ProgressBar' => '1.18',
		   'YAML' => '0.35',
		  },
   create_makefile_pl=>'passthrough',
);

$build->create_build_script;

