package Module::CPANTS::Generator::Uses;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Spec::Functions qw(catfile);
use YAML qw(:all);
use Module::ExtractUse;

use vars qw($VERSION);
$VERSION = "0.26";

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $modules=$cpants->{metric}{modules_list};
    my $files=$cpants->{metric}{files_list};
    my @tests=grep {m|^t/|} @$files;
    
    my $mods_in_dist=$cpants->{metric}{modules_in_dist};
    my %skip=map {$_->{module}=>1 } @$mods_in_dist;

    my $testdir=$cpants->testdir;

    # used in modules
    my $p=Module::ExtractUse->new;
    foreach (@$modules) {
        $p->extract_use(catfile($testdir,$_));
    }

    my %used;
    while (my ($mod,$cnt)=each%{$p->used}) {
        next if $skip{$mod};
        $used{$mod}=$cnt;
    }

    $cpants->{metric}{uses}=\%used;

    # used in tests
    my %used_tests;
    foreach my $tf (@tests) {
        open(FILE,catfile($testdir,$tf)) || next;
        my $file=join('',<FILE>);
        close FILE;

        my @used = $file=~/use ([\w:]+)/g;
        foreach (@used) {
            next if $skip{$_};
            $used_tests{$_}++;
        }
    }
    $cpants->{metric}{uses_in_tests}=\%used_tests;
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
            return 0 unless $uses->{strict};
            return 1 if $uses->{strict} == $modules;
            return 0;
        },
    },

    {
        name=>'has_test_pod',
        type=>'basic',
        error=>q{Doesn't include a test for pod correctness (Test::Pod)},
        code=>sub {
            my $m=shift;
            my $uses=$m->{uses_in_tests};
            return 1 if $uses->{'Test::Pod'};
            return 0;
        },
    },
    {
        name=>'has_test_pod_coverage',
        type=>'basic',
        error=>q{Doesn't include a test for pod coverage (Test::Pod::Coverage)},
        code=>sub {
            my $m=shift;
            my $uses=$m->{uses_in_tests};
            return 1 if $uses->{'Test::Pod::Coverage'};
            return 0;
        },
    },

    
#    {
#     name=>'use_warnings',
#     type=>'basic',
#     error=>q{This distribution does not use 'warnings' in all of its modules.},
#     code=>sub {
#	 my $metric=shift;
#	 my $modules=$metric->{modules} || 0;
#	 return 0 unless $modules;
#	 my $uses=$metric->{uses};
#	 foreach (@$uses) {
#	     next unless $_->{module} eq 'warnings';
#	     return 1 if $modules <= $_->{count};
#	 }
#     },
#    },
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
"create table uses_in_tests (
  id integer primary key,
  distid integer,
  module text,
  count integer
)",
"CREATE INDEX uses_tests_distid_idx on uses (distid)",
"CREATE INDEX uses_tests_module_idx on uses (module)",



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

