package Module::CPANTS::Generator::Uses;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Spec::Functions qw(catfile);
use YAML qw(:all);
use Module::ExtractUse;

use vars qw($VERSION);
$VERSION = "0.24";

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $modules=$cpants->{metric}{modules_list};
    my $testdir=$cpants->testdir;

    my $p=Module::ExtractUse->new;

    foreach (@$modules) {
	$p->extract_use(catfile($testdir,$_));
    }

    my $mods_in_dist=$cpants->{metric}{modules_in_dist};
    my %skip=map {$_->{module}=>1 } @$mods_in_dist;

    my @used;
    while (my ($used,$cnt)=each%{$p->used}) {
	next if $skip{$used};
	push(@used,{module=>$used,count=>$cnt});
    }

    $cpants->{metric}{uses}=\@used;
}


##################################################################
# Kwalitee Indicators
##################################################################

__PACKAGE__->kwalitee_definitions
  ([
    {
     name=>'use_strict',
     type=>'basic',
     error=>q{This distribution does not use 'strict' in all of its modules.},
     code=>sub {
	 my $metric=shift;
	 my $modules=$metric->{modules} || 0;
	 return 0 unless $modules;
	 my $uses=$metric->{uses};
	 foreach (@$uses) {
	     next unless $_->{module} eq 'strict';
	     return 1 if $modules == $_->{count};
	 }
     },
    },
    {
     name=>'use_warnings',
     type=>'basic',
     error=>q{This distribution does not use 'warnings' in all of its modules.},
     code=>sub {
	 my $metric=shift;
	 my $modules=$metric->{modules} || 0;
	 return 0 unless $modules;
	 my $uses=$metric->{uses};
	 foreach (@$uses) {
	     next unless $_->{module} eq 'warnings';
	     return 1 if $modules == $_->{count};
	 }
     },
    },
   ]);



##################################################################
# DB
##################################################################

sub sql_fields_dist { return '' }

sub sql_other_tables {
    return
[
"create table uses (
  id integer primary key,
  distid integer,
  module text,
  count integer
)",
"CREATE INDEX uses_distid_idx on uses (distid)",
"CREATE INDEX uses_module_idx on uses (module)",
];
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Uses - parse use statements

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Generator::Uses is Copyright (c) 2003,2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut

