package Module::CPANTS::Generator::Uses;
use warnings;
use strict;
use File::Spec::Functions qw(catfile);
use Module::ExtractUse;

sub order { 100 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $dist=shift;
    
    my $testdir=$dist->testdir;
    my @modules=$dist->modules;
    my $files=$dist->files_array;
    my @tests=grep {m|^t/|} @$files;
    
    my %skip=map {$_->module=>1 } @modules;
    my %uses;
    
    # used in modules
    my $p=Module::ExtractUse->new;
    foreach (@modules) {
        $p->extract_use(catfile($testdir,$_->file));
    }

    while (my ($mod,$cnt)=each%{$p->used}) {
        next if $skip{$mod};
        $uses{$mod}={
            module=>$mod,
            in_code=>$cnt,
            in_tests=>0,
        };
    }
    
    # used in tests
    my $pt=Module::ExtractUse->new;
    foreach my $tf (@tests) {
        $pt->extract_use(catfile($testdir,$tf));
    }
    while (my ($mod,$cnt)=each%{$pt->used}) {
        next if $skip{$mod};
        if ($uses{$mod}) {
            $uses{$mod}{'in_tests'}=$cnt;
        } else {
            $uses{$mod}={
                module=>$mod,
                in_code=>0,
                in_tests=>$cnt,
            }
        }
    }

    foreach (values %uses) {
        $dist->add_to_uses($_);
    }
    return 1;
}

##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'use_strict',
            error=>q{This distribution does not use 'strict' in all of its modules.},
            code=>sub {
                my $dist=shift;
                my $modules=$dist->modules;
                return 0 unless $modules;
                my ($strict)=Module::CPANTS::DB::Uses->search(dist=>$dist->id,module=>'strict');
                return 0 unless $strict;
                return 1 if $strict->in_code >= $modules->count;
                return 0;
            },
        },
        {
            name=>'has_test_pod',
            error=>q{Doesn't include a test for pod correctness (Test::Pod)},
            code=>sub {
                my $dist=shift;
                return 1 if Module::CPANTS::DB::Uses->search(dist=>$dist->id,module=>'Test::Pod');
                return 0;
            },
        },
        {
            name=>'has_test_pod_coverage',
            error=>q{Doesn't include a test for pod coverage (Test::Pod::Coverage)},
            code=>sub {
                my $dist=shift;
                return 1 if Module::CPANTS::DB::Uses->search(dist=>$dist->id,module=>'Test::Pod::Coverage');
                return 0;
            },
        },
    ];
}



##################################################################
# DB
##################################################################

sub schema {
    return {
        uses=>[
            'id integer primary key',
            'dist integer not null default 0',
            'module text',
            'in_dist integer not null default 0',
            'in_code integer',
            'in_tests integer',
        ],
        index=>[
            "CREATE INDEX uses_id on uses(id)",
            "CREATE INDEX uses_dist on uses(dist)",
            "CREATE INDEX uses_module on uses(module)",
            "CREATE INDEX uses_in_dist on uses(in_dist)",
            "CREATE INDEX uses_in_code on uses(in_code)",
            "CREATE INDEX uses_in_tests on uses(in_tests)",
        ],
    }
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

