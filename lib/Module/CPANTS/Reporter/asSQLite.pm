package Module::CPANTS::Reporter::asSQLite;
use DBI;
use base 'Module::CPANTS::Reporter::DB';
use strict;
use warnings;
use FindBin;
use File::Spec::Functions;

use vars qw($VERSION);
$VERSION = "0.011";

use vars(qw($DBH $tables));

sub init {
    my $class=shift;
    my $cpants=shift;

    my $dbfile=catfile($FindBin::Bin,'cpants.db');
    if (-e $dbfile) {
	unlink($dbfile);
    }

    $DBH=DBI->connect("dbi:SQLite:dbname=cpants.db");

    foreach my $m (@{$cpants->tests}) {
	my $create_db=$m->create_db;
	foreach my $sql (@$create_db) {
	    $DBH->do($sql);
	}
    }

    my $flaw_sql=$class->get_create_flaw_table($cpants);
    $DBH->do($flaw_sql);
}

sub DBH {
    return $DBH;
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Reporter::asSQLite - CPANTS in a handy SQLite DB

=head1 SYNOPSIS

see L<Module::CPANTS::Reporter>

=head1 DESCRIPTION

This is a subclass of L<Module::CPANTS::Reporter::DB>. It's main
purpose is to generate a SQLite DB together with a standard DB in the
same CPANTS run.

The SQLite DB file is called F<cpants.db> and is generated at the
location where the CPANTS run was started.

It might generate a distribution around the SQLite file in the future.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

