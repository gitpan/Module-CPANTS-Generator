package Module::CPANTS::Generator::Unpack;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Copy;
use File::Path;
use File::Spec::Functions qw(catdir catfile);
use File::stat;

use vars qw($VERSION);
$VERSION = "0.21";


##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;

    my $package=$cpants->package;
    my $temppath=$cpants->temppath;
    my $di=$cpants->distnameinfo;

    unless ($cpants->conf->force) {
	# todo:
	# read in old file and check 'generated_with'
	# dont skip if version is newer
	if (-e $cpants->metricfile) {
	    print "\tallready tested, skipping\n" unless $cpants->conf->quiet;
	    $cpants->abort(1);
	    return;
	}
    }

    # distinfo
    my $ext=$di->extension || '';
    my ($major,$minor);
    if ($di->version) {
	($major,$minor)=$di->version=~/^(\d+)\.(.*)/;
    }
    $major=$di->dist unless defined($major);

    $cpants->{metric}{distribution}=
      {
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
	$cpants->{metric}{distribution}{extractable}=0;
	$cpants->abort(1);
#	print "NOT EXTRACTABLE\n";
	return;
    }
    $cpants->{metric}{distribution}{extractable}=1;


    # size
    my $size_packed=-s $temppath;
    $cpants->{metric}{size}{packed}=$size_packed;

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
    $cpants->{metric}{distribution}{extracts_nicely}=$extracts_nicely;
    $cpants->{metric}{release}{epoch}=$stat->mtime;
    $cpants->{metric}{release}{date}=localtime($stat->mtime);

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
     code=>sub { shift->{distribution}{extractable} ? 0.5 : -1 },
    },
    {
     name=>'extracts_nicely',
     type=>'basic',
     error=>q{This package doesn't create a directory and extracts its content into this directory. Instead, it spews its content into the current directory, making it really hard/annoying to remove the unpacked package.},
     code=>sub { shift->{distribution}{extracts_nicely} ? 1 : 0},
    },
    {
     name=>'has_version',
     type=>'basic',
     error=>"The package filename (eg. Foo-Bar-1.42.tar.gz) does not include a version number (or something that looks like a reasonable version number to CPAN::DistnameInfo)",
     code=>sub { shift->{distribution}{version} ? 1 : 0 }
    }

   ]);


##################################################################
# DB
##################################################################

sub create_db {
    return
[
"create table distribution (
  dist varchar(150),
  dist_without_version varchar(150),
  package varchar(150),
  version varchar(50),
  version_major bigint,
  version_minor varchar(30),
  extension varchar(25),
  extracts_nicely tinyint unsigned not null default 0,
  extractable tinyint unsigned not null default 0
)",
"CREATE INDEX dist_dist_idx on distribution (dist)",

"create table size (
  dist varchar(150),
  packed bigint default 0,
  unpacked bigint default 0
)",
"CREATE INDEX size_dist_idx on size (dist)",

"create table release (
  dist varchar(150),
  epoch bigint default 0,
  date date
)",
"CREATE INDEX release_dist_idx on release (dist)"


];
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
