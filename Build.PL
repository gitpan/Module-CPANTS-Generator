use strict;
use Module::Build;
use File::Spec::Functions;

my $build = Module::Build->new
  (
   module_name => 'Module::CPANTS::Generator',
   license     => 'perl',
   requires    => {
		   'CPANPLUS'    => '0.042',
		   'CPAN::DistnameInfo'=>'0.04',
		   'AppConfig'=>'0',
		   'Test::More'  => '0.01',
		  },
#   script_files=>['examples/generate.pl'],
   create_makefile_pl=>'passthrough',
);


=pod

my $home=$ENV{'HOME'};
my $cpants_location=$build->prompt("Where do you want CPANTS to reside?\n(you'll need about 2 GB free disk space)",catdir($home,'cpants'));

$build->copy_if_modified({
			  from=>'examples',
			  to=>$cpants_location,
			 });

=cut


$build->create_build_script;
