use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'	=> 'Module::CPANTS::Generator',
  'VERSION_FROM' => 'lib/Module/CPANTS/Generator.pm',
  'PREREQ_PM' => {
    'CPANPLUS'    => '0.042',
    'DBD::SQLite' => '0.25',
    'Template'    => '2.08',
    'Test::More'  => '0.01',
  },
  'PL_FILES' => {},
  'DIR' => [],
);
