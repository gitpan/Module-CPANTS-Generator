package Module::CPANTS::Generator::ModuleInfo;
use strict;
use Carp;
use CPANPLUS;
use Storable;
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

sub generate {
  my $self = shift;

  my $cpants = {};
  eval {
    $cpants = retrieve("cpants.store");
  };
  # warn $@ if $@;

  my $cp = $self->cpanplus || croak("No CPANPLUS object");

  my %seen;
  my $count;
#  foreach my $module (sort { $a->package cmp $b->package } values %{$cp->module_tree}) {
  foreach my $module (values %{$cp->module_tree}) {
    my $package = $module->package;
    next unless $package;
    next if $seen{$package}++;
    my $author = $module->author;
    my $description = $module->description;
    $cpants->{$package}->{author} = $author;
    $cpants->{$package}->{description} = $description;
  }

  store($cpants, "cpants.store");
}

1;

__END__

=head1 NAME

Module::CPANTS::Generator::ModuleInfo - Find author, description

=head1 SYNOPSIS

  use Module::CPANTS::Generator::ModuleInfo;

  my $m = Module::CPANTS::Generator::ModuleInfo->new;
  $m->cpanplus($cpanplus);
  $m->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It goes through the
CPANPLUS module tree and adds information about distribution author
and description.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.
