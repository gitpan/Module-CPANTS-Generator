package Module::CPANTS::Reporter::DataDumper;
use strict;
use warnings;
use Data::Dumper;
use base 'Module::CPANTS::Reporter';

use vars qw($VERSION);
$VERSION = "0.011";

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
    print Dumper(\%data);
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Reporter::DataDumper - dump all data to STDOUT

=head1 SYNOPSIS

see L<Module::CPANTS::Reporter>

=head1 DESCRIPTION

Simple and straight-forward (and also not very usefull..): Collect
metrics of all distributions in a package global hash and use
Data::Dumper to print it.

=head2 Methods

=head3 init

Not used.

=head3 report

Store $metrics->data and $metrics->flaws in hash

=head3 finish

   print Dumper(\%data);

(one line of code says more then ten lines of docs...)

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

