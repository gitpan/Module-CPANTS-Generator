package Module::CPANTS::Generator::Files;
use strict;
use Carp;
use Cwd;
use File::Spec::Functions;
use Storable;
use vars qw($VERSION);
$VERSION = "0.003";

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

sub generate {
  my $self = shift;

  my $cpants = {};
  eval {
    $cpants = retrieve("cpants.store");
  };
  # warn $@ if $@;
  my $origdir = cwd;

  my $dir = $self->directory || croak("No directory specified");
  chdir $dir || croak("Could not chdir into $dir");

  foreach my $dist (sort grep { -d } <*>) {
    my @files;
    foreach my $file (qw(Makefile.PL README Build.PL META.yml SIGNATURE MANIFEST)) {
      if (-f catfile($dist, $file)) {
	push @files, $file;
      }
      $cpants->{$dist}->{files} = \@files;

    }
  }

  chdir $origdir;
  store($cpants, "cpants.store");
}

1;


__END__

=head1 NAME

Module::CPANTS::Generator::Files - Generate file information

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Files;

  my $f = Module::CPANTS::Generator::Files->new;
  $f->directory("unpacked");
  $f->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It scans through an
unpacked CPAN looking for specific files.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.
