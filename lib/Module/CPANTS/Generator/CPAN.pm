package Module::CPANTS::Generator::CPAN;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use CPANPLUS::Backend;

use vars qw($VERSION $cp %packages);
$VERSION = "0.21";

$cp=Module::CPANTS::Generator->get_cpan_backend;

%packages=map {$_->package=>{cpanid=>$_->author,dslip=>$_->dslip}}
  grep {$_->package} values %{$cp->module_tree};

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;

    my $package=$cpants->package;

    $cpants->{metric}{cpan}=$packages{$package};
    return;
}


##################################################################
# Kwalitee Indicators
##################################################################



##################################################################
# DB
##################################################################

sub create_db {
    return
["create table cpan (
  dist varchar(150),
  cpanid varchar(10),
  dslip varchar(10)
)",
"CREATE INDEX cpan_dist_idx on cpan (dist)",

];
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

Module::CPANTS::Generator::Unpack is Copyright (c) 2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
