package Module::CPANTS::Generator::FindModules;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';


##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $testdir=$cpants->testdir;

    my $files=$cpants->files();
    my $dirs=$cpants->dirs();

    my @modules;
    my @module_files;

    my @modules_basedir=grep {/^[^\/]+\.pm$/} @$files;
    $cpants->{metric}{modules_in_basedir}=scalar @modules_basedir;
    
    if (@modules_basedir) {
        #$cpants->{metric}{modules_raw}{list_basedir}=\@modules_basedir;
        push(@module_files,@modules_basedir);
        $cpants->distnameinfo->dist=~/^(.*)-\w+/i;
        my $module_name=$1 || "UNKNOWN";
        $module_name=~s/-/::/g;
        foreach (@modules_basedir) {
            s/\.pm$//;
            push(@modules,$module_name."::".$_);
        }
    }

    if ($cpants->{metric}{dir_lib}) {
        my @modules_path;
        my $cnt=0;
        foreach (@$files) {
            next unless m|^lib/(.*)\.pm$|;
            push(@module_files,$_);
            my $raw=$1;
            $raw=~s|/|::|g;
            push(@modules,$raw);
            $cnt++;
        }
        $cpants->{metric}{modules_in_lib}=$cnt;
    }

    $cpants->{metric}{modules_list}=\@module_files;
    $cpants->{metric}{modules}=scalar @module_files;

    my @mods_in_dist=map {{module=>$_}} @modules;
    $cpants->{metric}{modules_in_dist}=\@mods_in_dist;

    return;
}



##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions([{
    name=>'proper_libs',
    type=>'basic',
    error=>q{There is more than one .pm file in the base dir, or the .pm files are not in directoy lib.},
    code=>sub { 
        my $m=shift;
        return 1 if $m->{modules_in_basedir}==0 && $m->{dir_lib};
        return 1 if $m->{modules_in_basedir}==1;
        return 0;
    },
}]);

##################################################################
# DB
##################################################################

sub sql_fields_dist {
    return 
"   modules integer,
   modules_list text,
   modules_in_lib integer,
   modules_in_basedir integer,
";
}

sub sql_other_tables {
    return ["
create table modules_in_dist (
    id integer primary key,
    dist text,
    module text
)",
    "CREATE INDEX mid_dist_idx on modules_in_dist (dist)\n"];
}

1;


__END__

=pod

=head1 NAME

Module::CPANTS::Generator::FindModules - Find modules in distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Generator::FindModules is Copyright (c) 2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.


=cut

