package Module::CPANTS::Reporter::asHash;
use strict;
use warnings;
use Data::Dumper;
use base 'Module::CPANTS::Reporter';
use FindBin;
use DateTime;
use Carp;
use File::Spec::Functions;
use File::Copy;

our %data;

sub init { return }

sub report {
    my $reporter=shift;
    my $metric=shift;
    my $cpants_data=$metric->data;
    $cpants_data->{flaws}=$metric->flaws;
    $data{$metric->dist}=$cpants_data;
    return;
}

sub finish {
    my $reporter=shift;
    chdir($FindBin::Bin);

    my $version="0.".Module::CPANTS::Generator->run_id;

    # make dist dir, lib & test dir
    my $dir="Module-CPANTS-asHash-$version";

    if (-e $dir) {
	move($dir,$dir."_".time);
    }

    my @dirs=($dir,catdir($dir,'t'));
    my $libdir=$dir;
    foreach (qw(lib Module CPANTS)) {
	$libdir=catdir($libdir,$_);
	push(@dirs,$libdir);
    }

    foreach (@dirs) {
	mkdir($_) || croak ("cannot make dir $_: $!");
    }

    # create basic files of dist
    $/="%%%%\n";
    foreach my $file (<DATA>) {
	chomp($file);
	my @data=split(/\n/,$file);
	my $filename=shift(@data);
	my $content=join("\n",@data);

	my $filepath=catdir($dir,$filename);
	open (FILE,">$filepath") || croak "Cannot create file $filepath: $!";
	print FILE $content;
	close FILE;
    }

    my $cpants_dump = 'my ' . Data::Dumper->Dump([\%data], [qw(cpants)]);

    my $kwalitee_defs=Module::CPANTS::Generator->kwalitee_defs;
    my $kwalitee_dump = 'my ' . Data::Dumper->Dump([$kwalitee_defs], [qw(kwalitee)]);

    my $kwalitee_pod;
    foreach my $id (sort keys %$kwalitee_defs) {
	$kwalitee_pod.="=head2 $id\n\n";
	my $info=$kwalitee_defs->{$id};
	$kwalitee_pod.=$info->{short}."\n\n".$info->{long}."\n\nKwalitee: ".
	  $info->{k}."\n\ntested in: ".$info->{class}."\n\n";
    }

    my $code=<<'EOCODE';
package Module::CPANTS::asHash;
use strict;
use vars qw($VERSION);
$VERSION = "%version%";

# This module is autogenerated!

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

sub data {
  my $self = shift;

  %cpants%

  return $cpants;
}

sub kwalitee {
  my $self = shift;

  %kwalitee%

  return $kwalitee;
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::asHash - CPANTS data as a big Hash

=head1 SYNOPSIS

      use Module::CPANTS::asHash;
      my $c = Module::CPANTS::asHash->new();
      my $cpants = $c->data;

=head1 DESCRIPTION


%kwalitee_pod%

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

EOCODE

    $code=~s/%version%/$version/;
    $code=~s/%cpants%/$cpants_dump/;
    $code=~s/%kwalitee%/$kwalitee_dump/;
    $code=~s/%kwalitee_pod%/$kwalitee_pod/;

    my $libpath=catdir($libdir,"asHash.pm");
    open (FILE,">$libpath") || croak "Cannot create file $libpath: $!";
    print FILE $code;
    close FILE;

}

1;

=pod

=head1 NAME

Module::CPANTS::Reporter::asHash - CPANTS as a hash packed in a distribution

=head1 SYNOPSIS

see L<Module::CPANTS::Reporter>

=head1 DESCRIPTION

Module::CPANTS::Reporter::asHash collects CPANTS metrics for all
distributions in one hash. This hash is packed up as a CPAN
distribution of its own.

=head2 Methods

=head3 init

Not used.

=head3 report

Adds $metrics->data to a package global hash. Also adds
$metrics->flaws.

=head3 finish

Generate the package using a frightening combination of Here
documents, the __DATA__ section and a homegrown templating system (ok,
it's a simple regex).

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

__DATA__
Build.PL
use strict;
use Module::Build;
use File::Spec::Functions;

my $build = Module::Build->new
  (
   module_name => 'Module::CPANTS::as::Hash',
   license     => 'perl',
   requires    => { },

);
$build->create_build_script;
%%%%
Changes

2003-10-13:
  * initial release after take-over

%%%%
MANIFEST
Build.PL
Changes
MANIFEST
Makefile.PL
META.yml
README
test.pl
lib/Module/CPANTS/as/Hash.pm
%%%%
Makefile.PL
unless (eval "use Module::Build::Compat 0.02; 1" ) {
    print "This module requires Module::Build to install itself.\n";
    require ExtUtils::MakeMaker;
    my $yn = ExtUtils::MakeMaker::prompt
      ('  Install Module::Build now from CPAN?', 'y');
    unless ($yn =~ /^y/i) {
	warn " *** Cannot install without Module::Build.  Exiting ...\n";
	exit 1;
    }
    require Cwd;
    require File::Spec;
    require CPAN;
    # Save this 'cause CPAN will chdir all over the place.
    my $cwd = Cwd::cwd();
    my $makefile = File::Spec->rel2abs($0);
    CPAN::Shell->install('Module::Build::Compat');
    chdir $cwd or die "Cannot chdir() back to $cwd: $!";
    exec $^X, $makefile, @ARGV;  # Redo now that we have Module::Build
}
Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();
%%%%
README
NAME
    Module::CPANTS::asHash - CPANTS data in one big hash

SYNOPSIS
      use Module::CPANTS::asHash;
      my $c = Module::CPANTS::as::Hash->new();
      my $cpants = $c->data;

DESCRIPTION
      tbd

AUTHOR
    Thomas Klausner <domm@zsi.at>

LICENSE
    This code is distributed under the same license as Perl.

%%%%
t/load.t
use Test;
BEGIN { plan tests => 1 };
use Module::CPANTS::asHash;
ok(1);
