use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'	=> 'Module::CPANTS',
  'VERSION_FROM' => 'lib/Module/CPANTS.pm',
  'PREREQ_PM' => {'Test::More' => '0.01', 'CPANPLUS' => '0.042' },
  'PL_FILES' => {},
);
