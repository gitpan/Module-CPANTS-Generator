#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator::Files;
use Module::CPANTS::Generator::ModuleInfo;
use Module::CPANTS::Generator::Prereq;
use Module::CPANTS::Generator::Unpack;
use Storable;
use Template;

my $version = "0.004";

my $unpacked = "$FindBin::Bin/../unpacked/";

my $cpanplus = CPANPLUS::Backend->new(conf => {verbose => 0, debug => 0});
#$cpanplus->reload_indices(update_source => 1);

if (-d $unpacked) {
  print "* Using existing unpacked CPAN\n";
} else {
  print "* Unpacking CPAN...\n";
  my $u = Module::CPANTS::Generator::Unpack->new;
  $u->cpanplus($cpanplus);
  $u->directory($unpacked);
  $u->unpack;
}

print "* Generating module info...\n";
my $m = Module::CPANTS::Generator::ModuleInfo->new;
$m->cpanplus($cpanplus);
$m->directory($unpacked);
$m->generate;

print "* Generating module prerequisites...\n";
my $p = Module::CPANTS::Generator::Prereq->new;
$p->cpanplus($cpanplus);
$p->directory($unpacked);
$p->generate;

print "* Generating file info...\n";
my $f = Module::CPANTS::Generator::Files->new;
$f->directory($unpacked);
$f->generate;

print "* Generating CPANTS.pm...\n";
my $cpants = retrieve("cpants.store") || die;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 0;
my $data = 'my ' . Data::Dumper->Dump([$cpants], [qw(cpants)]);

my $vars = {
  cpants => $data,
  version => $version,
};

my $tt = Template->new();
$tt->process('Module-CPANTS/lib/Module/CPANTS.tt', $vars, 'Module-CPANTS/lib/Module/CPANTS.pm')
  || die $tt->error(), "\n";

print "* All done\n";
