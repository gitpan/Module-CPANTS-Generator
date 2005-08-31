package Module::CPANTS::Generator::Unpack;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Copy;
use File::Path;
use File::Spec::Functions qw(catdir catfile);
use File::stat;
use CPAN::DistnameInfo;
use Archive::Any;

my $testdir=Module::CPANTS::Config->testdir;

sub order { 1 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $dist=shift;

    # DistnameInfo
    my $di=CPAN::DistnameInfo->new($dist->from);
    my ($major,$minor);
    if ($di->version) {
        ($major,$minor)=$di->version=~/^(\d+)\.(.*)/;
    }
    $major=0 unless defined($major);
    my $ext=$di->extension || 'unknown';
    
    $dist->dist($di->distvname);
    $dist->extension($ext);
    $dist->version($di->version);
    $dist->version_major($major);
    $dist->version_minor($minor);
    $dist->dist_without_version($di->dist);
    $dist->pauseid($di->cpanid);
    
    # extract
    chdir($testdir);
    my $tarball=$dist->testfile;
    my $archive=Archive::Any->new($tarball);
    unless ($ext eq 'tar.gz' || $ext eq 'tgz' || $ext eq 'zip') {
        $dist->extractable(0);
        unlink($tarball);
        print "NOT EXTRACTABLE\n";
        return;
    }
    $dist->extractable(1),

#    if ($ext eq 'tar.gz' || $ext eq 'tgz') {
#        system("tar xzf $tarball 2>/dev/null") == 0  || warn "cannot unpack: tar xzf $tarball 2>/dev/null";
#    } elsif ($ext eq 'zip') {
#        system("unzip", "-q", $tarball) == 0 || warn "cannot unpack: unzip -q $tarball";
#    } else {
#        $dist->extractable(0);
#        unlink($tarball);
#        print "NOT EXTRACTABLE\n";
#        return;
#    }

    
    # size
    $dist->size_packed(-s $tarball);

    $archive->extract();

    # remove tarball
    unlink($tarball);
    
    # check if package is polite & get release date
    my $extracts_nicely=0;
    my $stat;
    
    opendir(DIR,".");
    my @stuff=grep {/\w/} readdir(DIR);
    if (@stuff == 1) {
        $extracts_nicely=1 if $di->distvname eq $stuff[0];
        $dist->testdir(catdir($testdir,$stuff[0]));
        $stat=stat($dist->testdir);
    } else {
        my @pm=grep {/\.pm$/} @stuff;
        my $file=$pm[rand(@pm)];
        $stat=stat(catfile($testdir,$file));

        mkdir(catdir($testdir,'testing'));
        move('*','testing') || warn $dist->dist.": Cannot move extracted data to testing: $!";
        $dist->testdir(catdir($testdir,'testing'));
    }
       
    $dist->extracts_nicely($extracts_nicely);
    $dist->released_epoch(scalar $stat->mtime);
    $dist->released_date(scalar localtime($stat->mtime));
    $dist->update; 
    
    chdir($dist->testdir);
    return 1;
}


##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'extractable',
            type=>'basic',
            error=>q{This package uses an unknown packaging format. CPANTS can handle tar.gz, tgz and zip archives. No kwalitee metrics have been calculated.},
            code=>sub { shift->extractable ? 1 : -100 },
        },
        {
            name=>'extracts_nicely',
            type=>'basic',
            error=>q{This package doesn't create a directory and extracts its content into this directory. Instead, it spews its content into the current directory, making it really hard/annoying to remove the unpacked package.},
            code=>sub { shift->extracts_nicely ? 1 : 0},
        },
        {
            name=>'has_version',
            type=>'basic',
            error=>"The package filename (eg. Foo-Bar-1.42.tar.gz) does not include a version number (or something that looks like a reasonable version number to CPAN::DistnameInfo)",
            code=>sub { shift->version ? 1 : 0 }
        },
        {
            name=>'has_proper_version',
            type=>'basic',
            error=>"The version number isn't a number. It probably contains letter, which it shouldn't",
            code=>sub { my $v=shift->version;
                 return 0 unless $v;
                 return 1 if ($v=~/^[\d\.]+$/);
                 return 0;
            }
        },
        {
            name=>'no_cpants_errors',
            type=>'basic',
            error=>"There where problems during CPANTS testing. Those problems are either caused by some very strange behaviour of this distribution or a bug in CPANTS.",
            code=>sub { shift->cpants_errors ? 0 : 1 }
        },
    ];
}

   
##################################################################
# DB
##################################################################

sub schema {
    return {
        version=>['cpants text','db text'],
        dist=>[
            'id INTEGER PRIMARY KEY',
            'kwalitee integer',
            'generated_at text',
            'generated_with text',
            'dist text',
            'package text',
            'dist_without_version text',
            'version text',
            'version_major text',
            'version_minor text',
            'extension text',
            'extractable integer not null default 0',
            'extracts_nicely integer not null default 0',
            'size_packed integer',
            'size_unpacked integer',
            'released_epoch text',
            'released_date text',
            'cpants_errors text',
        ],
        index=>[
            'create unique index dist_id on dist(id)',
            'create unique index dist_wv on dist(dist_without_version)',
            'create unique index dist_dist on dist(dist)',
        ],
    };
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Unpack - Unpacking of a package

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

based on work by Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Module::CPANTS::Generator::Unpack is Copyright (c) 2003,2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
