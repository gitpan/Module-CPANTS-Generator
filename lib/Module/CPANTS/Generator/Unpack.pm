package Module::CPANTS::Generator::Unpack;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Copy;
use File::Path;
use File::Spec::Functions qw(catdir catfile);
use File::stat;

use vars qw($VERSION);
$VERSION = "0.24";


##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;

    my $package=$cpants->package;
    my $temppath=$cpants->temppath;
    my $di=$cpants->distnameinfo;

#    unless ($cpants->conf->force) {
	# todo:
	# read in old file and check 'generated_with'
	# dont skip if version is newer
#	if (-e $cpants->metricfile) {
#	    $cpants->abort(1);
#	    return;
#	}
#    }

    # distinfo
    my $ext=$di->extension || '';
    my ($major,$minor);
    if ($di->version) {
        ($major,$minor)=$di->version=~/^(\d+)\.(.*)/;
    }
    $major=$di->dist unless defined($major);

    $cpants->{metric}=
      {
       dist=>$cpants->dist,
       package=>$di->filename,
       extension=>$ext,
       version=>$di->version,
       version_major=>$major,
       version_minor=>$minor,
       dist_without_version=>$di->dist,
      };

    # extract
    copy(catfile($cpants->distsdir,$package),$cpants->tempdir) || die $!;
    chdir($cpants->tempdir);

    if ($ext eq 'tar.gz' || $ext eq 'tgz') {
        system("tar xzf $temppath 2>/dev/null");
    } elsif ($ext eq 'zip') {
        system("unzip", "-q", $temppath);

# gz is not supported by CPAN::DistnameInfo
#    } elsif ($ext eq 'gz') {
#	system("gzip", "-d", $temppath);

    } else {
        $cpants->{metric}{extractable}=0;
        $cpants->abort(1);
#	print "NOT EXTRACTABLE\n";
        return;
    }
    $cpants->{metric}{extractable}=1;


    # size
    my $size_packed=-s $temppath;
    $cpants->{metric}{size_packed}=$size_packed;

    # remove tarball
    unlink($cpants->temppath);

    # check if package is polite & get release date
    my $extracts_nicely=0;
    my $stat;
    if (-d catdir($cpants->tempdir,$di->distvname)) {
        $extracts_nicely=1;
        $cpants->testdir(catdir($cpants->tempdir,$di->distvname));
        $stat=stat($cpants->testdir);

    } else {
        opendir(DIR,".");
        my @stuff=grep {/\w/} readdir(DIR);
        closedir DIR;

	# if there is only one thing in this dir, assume it's a dir
	# else, get a random .pm file and use its mtime
	if (@stuff==1) {
	    $cpants->testdir(catdir($cpants->tempdir,$stuff[0]));
	    $stat=stat($cpants->testdir);
	} else {
	    $cpants->testdir($cpants->tempdir);

	    my @pm=grep {/\.pm$/} @stuff;
	    my $file=$pm[rand(@pm)];
	    $stat=stat(catfile($cpants->testdir,$file));
	}
    }
    $cpants->{metric}{extracts_nicely}=$extracts_nicely;
    $cpants->{metric}{released_epoch}=$stat->mtime;
    $cpants->{metric}{released_date}=localtime($stat->mtime);

    chdir($cpants->testdir);
    return;
}


##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions
  ([
    {
     name=>'extractable',
     type=>'basic',
     error=>q{This package uses an unknown packaging format. CPANTS can handle tar.gz, tgz and zip archives. No kwalitee metrics have been calculated.},
     code=>sub { shift->{extractable} ? 1 : -1 },
    },
    {
     name=>'extracts_nicely',
     type=>'basic',
     error=>q{This package doesn't create a directory and extracts its content into this directory. Instead, it spews its content into the current directory, making it really hard/annoying to remove the unpacked package.},
     code=>sub { shift->{extracts_nicely} ? 1 : 0},
    },
    {
     name=>'has_version',
     type=>'basic',
     error=>"The package filename (eg. Foo-Bar-1.42.tar.gz) does not include a version number (or something that looks like a reasonable version number to CPAN::DistnameInfo)",
     code=>sub { shift->{version} ? 1 : 0 }
    },
    {
     name=>'has_proper_version',
     type=>'basic',
     error=>"The version number isn't a number. It probably contains letter, which it shouldn't",
     code=>sub { my $v=shift->{version};
                 return 0 unless $v;
                 return 1 if ($v=~/^[\d\.]+$/);
                 return 0;
 }
    },

    
    {
     name=>'no_cpants_errors',
     type=>'basic',
     error=>"There where problems during CPANTS testing. Those problems are either caused by some very strange behaviour of this distribution or a bug in CPANTS. ",
     code=>sub { shift->{analyse_errors} ? 0 : 1 }
    }


   ]);


##################################################################
# DB
##################################################################

sub sql_fields_dist {
    return "   dist text,
   package text,
   dist_without_version text,
   version text,
   version_major text,
   version_minor text,
   extension text,
   extractable integer,
   extracts_nicely integer,
   size_packed integer,
   size_unpacked integer,
   released_epoch text,
   released_date text,
   cpants_errors text,
   ";
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
