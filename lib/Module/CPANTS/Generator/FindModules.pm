package Module::CPANTS::Generator::FindModules;
use warnings;
use strict;

sub order { 30 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $dist=shift;
    
    my $files=$dist->files_array;
    
    my @modules_basedir=grep {/^[^\/]+\.pm$/} @$files;
    if (@modules_basedir) {
        my $namespace=$dist->dist_without_version || 'unkown';
        $namespace=~s/-[^-]+$//;
        $namespace=~s/-/::/g;
        foreach my $file (@modules_basedir) {
            my $module=$namespace."::".$file;
            $module=~s/\.pm$//;
            $dist->add_to_modules({
                module=>$module,
                file=>$file,
                in_basedir=>1,
                in_lib=>0,
            });
        }
    }

    if ($dist->dir_lib == 1) {
        my @modules_path;
        foreach my $file (@$files) {
            next unless $file=~m|^lib/(.*)\.pm$|;
            my $module=$1;
            $module=~s|/|::|g;
            $dist->add_to_modules({
                module=>$module,
                file=>$file,
                in_basedir=>0,
                in_lib=>1,
            });
        }
    }

    if (!@modules_basedir && !$dist->dir_lib) {
        my @modules_path;
        foreach my $file (@$files) {
            next unless $file=~/\.pm$/;
            next if $file=~m{/t/};
            next if $file=~m{/test/};
            $file=~m|(.*)\.pm$|;
            my $module=$1;
            $module=~s|/|::|g;
            $dist->add_to_modules({
                module=>$module,
                file=>$file,
                in_basedir=>0,
                in_lib=>0,
            });
        }
    }
    
    $dist->update;
    return 1;
}



##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'proper_libs',
            error=>q{There is more than one .pm file in the base dir, or the .pm files are not in directoy lib.},
            remedy=>q{Move your *.pm files in a directory named 'lib'. The directory structure should look like 'lib/Your/Module.pm' for a module named 'Your::Module'.},
            code=>sub { 
                my $dist=shift;
                my @modules=$dist->modules;
                return 0 unless @modules;

                my @in_basedir=grep { $_->file !~ m|/| } @modules;
                return 1 if $dist->dir_lib && @in_basedir == 0;
                return 1 if @in_basedir == 1;
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
        modules=>[
            'id INTEGER PRIMARY KEY',,
            'dist integer not null default 0',
            'module text',
            'file text',
            'in_lib integer not null default 0',
            'in_basedir integer not null default 0',
        ],
        index=>[
            "CREATE INDEX modules_dist on modules(dist)",
            "CREATE INDEX modules_lib on modules(in_lib)",
            "CREATE INDEX modules_basedir on modules(in_basedir)",
        ],
    };
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

