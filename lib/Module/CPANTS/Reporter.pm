package Module::CPANTS::Reporter;
use strict;
use warnings;
use Carp;

sub init {
    croak("'init' is a virtual method. It must be implemented in subclass of Module::CPANTS::Reporter.");
}
sub report {
    croak("'report' is a virtual method. It must be implemented in subclass of Module::CPANTS::Reporter.");
}
sub finish {
    croak("'finish' is a virtual method. It must be implemented in subclass of Module::CPANTS::Reporter.");
}



1;
__END__

=pod

=head1 NAME

Module::CPANTS::Reporter - Base class for CPANTS reporters

=head1 SYNOPSIS

This is only a base class providing an interface for subclasses to override.

Do not use this Class directly.

=head1 DESCRIPTION

Subclasses of C<Module::CPANTS::Reporter> should implement these
methods, all of which are class methods:

=head3 init

  Module::CPANTS::Reporter::Subclass->init($cpants);

Take a Module::CPANTS::Generator object as only argument. C<init>
is called only once when L<Module::CPANTS::Generator> loads all
reporter modules in L<load_reporter>.

You can use C<init> to initialise your reporter (e.g. set up a DB
connection, populate package globals, etc)

If your subclass doesn't need initialization, simply provide an empty
sub

  sub init { }

=head3 report

  Module::CPANTS::Reporter::Subclass->report($metric);

C<report> is called via $metric->report, which calls C<report> on each
registered reporter module.

C<report> is the core of each reporter module. Obviously, it reports
data somehow. CPANTS data is available via the
L<Module::CPANTS::Metrics> object passed in as an parameter,
especially it's L<data> method.

=head3 finish

  Module::CPANTS::Reporter::Subclass->finish($metric);

C<finish> takes no arguments and is called after running all tests for
each registered reporter module on all packages.

Use C<finish> to do some cleanup, or to report some data that's only
available after the whole CPANTS run.

=head1 SEE ALSO

Take a look at those modules for some ideas on reporters:

=over

=item *

L<Module::CPANTS::Reporter::DB> - save data in a DB

init and report

=item *

L<Module::CPANTS::Reporter::MakeAsHash> - Data::Dumper dump packed up
in a dist

report and finish

=item *

L<Module::CPANTS::Reporter::MakeAsSQLite> - generate a SQLite DB

subclass of Module::CPANTS::Reporter::DB

=head2 And don't forget:

Module::CPANTS::Generator

Module::CPANTS::Metrics

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Metrics is Copyright (c) 2003 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
