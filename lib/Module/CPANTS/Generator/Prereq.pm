package Module::CPANTS::Generator::Prereq;
use warnings;
use strict;
use File::Spec::Functions qw(catfile);
use YAML qw(:all);


sub order { 100 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $dist=shift;
    
    my $files=$dist->files_array;
    my $testdir=$dist->testdir;

    my $prereq;
    if (grep {/^META\.yml$/} @$files) {
        my $yaml;
        eval {
            $yaml=LoadFile(catfile($testdir,'META.yml'));
        };

        if ($yaml) {
            if ($yaml->{requires}) {
                $prereq=$yaml->{requires};
            }
        }
    } elsif (grep {/^Build\.PL$/} @$files) {
        open(IN,catfile($testdir,'Build.PL')) || return 1;
        my $m=join '', <IN>;
        close IN;
        my($requires) = $m =~ /requires.*?=>.*?\{(.*?)\}/s;
        eval "{ no strict; \$prereq = { $requires \n} }";
        
    } else {
        open(IN,catfile($testdir,'Makefile.PL')) || return 1;
        my $m=join '', <IN>;
        close IN;

        my($requires) = $m =~ /PREREQ_PM.*?=>.*?\{(.*?)\}/s;
        $requires||='';
        eval "{ no strict; \$prereq = { $requires \n} }";
    }
    
    return unless $prereq;
    if (!ref $prereq) {
        my $p={$prereq=>0};
        $prereq=$p;
    }
    while (my($requires,$version)=each%$prereq) {
        $version||=0;
        $version=0 unless $version=~/[\d\._]+/;
        $dist->add_to_prereqs({
            requires=>$requires,
            version=>$version,
        });
    }
    return 1;
}

##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators{
    return [
        {
            name=>'is_prereq',
            error=>q{This distribution is not required by another distribution by another author.},
            code=>sub {
                my $dist=shift;
                my $pauseid=$dist->author->pauseid;
                my $it=Module::CPANTS::DB::Dist->search_required_by_otherauthor(
                    $dist->id,$pauseid
                );
                my $required=$it->count;
                return 1 if $required;
            },
        },
    ];
}

##################################################################
# DB
##################################################################

sub schema {
    return {
        prereq=>[
            'id integer primary key',
            'dist integer not null default 0',
            'requires text',
            'version text',
            'in_dist integer not null default 0',
        ],
        index=>[
            'create index prereq_id on prereq(id)',
            'create index prereq_dist on prereq(dist)',
            'create index prereq_requires on prereq(requires)',
            'create index prereq_in_dist on prereq(in_dist)',

        ],
    }
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Prereq - parse PREREQ_PM and requires (Build.PL)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

based on work by Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Module::CPANTS::Generator is Copyright (c) 2003,2004,2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut

