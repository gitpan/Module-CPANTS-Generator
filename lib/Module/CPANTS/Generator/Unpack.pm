package Module::CPANTS::Generator::Unpack;
use strict;
use Carp;
use File::Spec::Functions qw(catfile);
use File::Copy;
use File::Path;
use vars qw($VERSION);
$VERSION = "0.002";

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

sub cpanplus {
  my($self, $cpanplus) = @_;
  if (defined $cpanplus) {
    $self->{CPANPLUS} = $cpanplus;
  } else {
    return $self->{CPANPLUS};
  }
}

sub directory {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{DIR} = $dir;
  } else {
    return $self->{DIR};
  }
}

sub unpack {
  my $self = shift;
  my $dir = $self->directory || croak("No directory specified");
  mkdir $dir;
  chdir $dir || croak("Could not chdir into $dir");

  my $cp = $self->cpanplus || croak("No CPANPLUS object");

  my %seen;
  my $count;
  foreach my $module (sort { $a->package cmp $b->package } values %{$cp->module_tree}) {
    my $package = $module->package;
    next if $seen{$package}++;
    $count++;
    print "$package\n";
    my $f = $module->fetch;
    if (-d $package) {
      print "  Already extracted, skipping\n";
      next;
    }
    if ($f =~ /\.tar\.gz$/ || $f =~ /\.tgz$/) {
      mkdir "test";
      chdir "test";
      system("tar", "xzf", $f);
      $self->check($package);
    } elsif ($f =~ /\.zip$/) {
      mkdir "test";
      chdir "test";
      system("unzip", "-q", $f);
      $self->check($package);
    } elsif ($f =~ /\.pm\.gz$/) {
    } else {
      print "Unknown format: $f\n";
    }
  }

  return $count;
}


sub check {
  my($self, $package) = @_;
  my @dirs = grep { -d $_ } <*>;
  my @files = grep { -f $_ } <*>;
  if (@files) {
    print "  Files found, copied\n";
    chdir "..";
    move("test", $package);
    return;
  }
  if (scalar(@dirs) == 1) {
    print "  One dir, copied\n";
    move($dirs[0], "../$package");
    chdir "..";
    return;
  } else {
    print "  No dirs or multiple dirs found, copied\n";
    chdir "..";
    move("test", $package);
    return;
  }
  print "  Some other case: @dirs, @files, aborting\n";
  chdir "..";
  rmtree "test";
  return;
}

1;

__END__

=head1 NAME

Module::CPANTS::Generator::Unpack - Unpack CPAN

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Unpack;

  my $u = Module::CPANTS::Generator::Unpack->new;
  $u->cpanplus($cpanplus);
  $u->directory("unpacked");
  $u->unpack;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It unpacks the whole
of CPAN to a directory using CPANPLUS. That is, it unpacks every
distribution which contains a module. This will take a while (20 mins)
and a lot of diskspace (1.8G).

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.