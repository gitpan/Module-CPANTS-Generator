package Module::CPANTS::Reporter::STDOUT;
use strict;
use warnings;
use base 'Module::CPANTS::Reporter';

use vars qw($VERSION);
$VERSION = "0.011";

sub init { return }

sub report {
    my $reporter=shift;
    my $metric=shift;

    print "+ ".$metric->dist."\n";

    print "\tKwalitee:\t".$metric->kwalitee."\t".sprintf("%6.2f",$metric->data->{'kwalitee'}*100)."%\n";
    print "\tFlaws:\t".join(', ',@{$metric->flaws})."\n" unless $metric->kwalitee == $metric->cpants->total_kwalitee;


    return;
}

sub finish { return }

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Reporter::STDOUT - print kwalitee and flaws to STDOUT

=head1 SYNOPSIS

see L<Module::CPANTS::Reporter>

=head1 DESCRIPTION

Print Kwalitee rating and flaws (if there are any) to SDTOUT.

This module is now used by cpants.pl to print to STDOUT instead of
printing directly from the script

=head2 Methods

=head3 init

Not used.

=head3 report

Print Distname, kwalitee rating (absolut and relative) and flaws

=head3 finish

Not used.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

