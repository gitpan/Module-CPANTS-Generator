package Module::CPANTS::Generator::CPAN;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use CPANPLUS::Backend;

use vars qw($VERSION $cp %packages);
$VERSION = "0.24";

$cp=Module::CPANTS::Generator->get_cpan_backend;

if ($cp) {
    %packages=map {$_->package=>{author=>$_->author,dslip=>$_->dslip}}
      grep {$_->package} values %{$cp->module_tree};
}

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;

    my $package=$cpants->package;
    my $cpan=$packages{$package};
    while (my ($k,$v)=each %{$cpan}) {
	$cpants->{metric}{$k}=$v;
    }
    return;
}


##################################################################
# Kwalitee Indicators
##################################################################



##################################################################
# DB
##################################################################

sub sql_fields_dist {
    return "   author text,
   dslip text,
";
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::CPAN - get metainfos from CPANPLUS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Generator::CPAN is Copyright (c) 2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
