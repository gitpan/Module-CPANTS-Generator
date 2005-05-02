package Module::CPANTS::Generator::Prereq;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Spec::Functions qw(catfile);
use YAML qw(:all);
use Module::MakefilePL::Parse;

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $files=$cpants->files;
    my $testdir=$cpants->testdir;

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
        open(IN,catfile($cpants->testdir,'Build.PL')) || return;
        my $m=join '', <IN>;
        close IN;
        my($requires) = $m =~ /requires.*?=>.*?\{(.*?)\}/s;
        eval "{ no strict; \$prereq = { $requires \n} }";
        
    } else {
        open(IN,catfile($cpants->testdir,'Makefile.PL')) || return;
        my $m=join '', <IN>;
        close IN;

        my($requires) = $m =~ /PREREQ_PM.*?=>.*?\{(.*?)\}/s;
        $requires||='';
        eval "{ no strict; \$prereq = { $requires \n} }";
    }

    return unless $prereq;
    foreach my $ver (values %$prereq) {
        $ver||=0;
        $ver=0 unless $ver=~/[\d\._]+/;
    }
    $cpants->{metric}{prereq}=$prereq;
}

##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions([{
    name=>'is_prereq',
    type=>'complex',
    error=>q{This distribution is only required by 2 or less other distributions.},
    code=>sub {
        my $metric=shift;
        my $DBH=Module::CPANTS::Generator->DBH;
        my $required_by=0;

        my $modules=$metric->{modules_in_dist};
        foreach (@$modules) {
            my $module=$_->{module};
            $required_by+=$DBH->selectrow_array("select count(dist) from prereq where requires=?",undef,$module);
        }

        if ($required_by>0) {
            $metric->{required_by}=$required_by;
            $DBH->do("update dist set required_by=? where dist=?",undef,$required_by,$metric->{dist});
        }

        if ($required_by>2) {
            $DBH->do("update kwalitee set kwalitee=?,is_prereq=1 where dist=?",undef,$metric->{kwalitee}{kwalitee}+1,$metric->{dist}) || die "foo $!";
            return 1;
        }
        return 0;
    },
}]);

##################################################################
# DB
##################################################################

sub sql_fields_dist {
    return "    required_by integer,\n";
}

sub sql_other_tables {
    return [
"create table prereq (
    id integer primary key,
    dist text,
    requires text,
    version text
)",
    "CREATE INDEX prereq_dist_idx on prereq (dist)\n",
    "CREATE INDEX prereq_requires_idx on prereq (requires)\n",];
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

