package Module::CPANTS::Generator::Files;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Find;
use File::Spec::Functions qw(catdir catfile abs2rel);

use vars qw($VERSION);
$VERSION = "0.21";


##################################################################
# Analyse
##################################################################

# global values needed for File::Find
our @files=();
our @dirs=();
our $size=0;

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $testdir=$cpants->testdir;

    # use File::Find to get unpacked size & filelist
    @files=();
    @dirs=();
    $size=0;
    find(\&get_files,$testdir);
    $cpants->{metric}{size}{unpacked}=$size;

    # munge filelist
    @files=map {abs2rel($_,$testdir)} @files;
    @dirs=map {abs2rel($_,$testdir)} @dirs;

    $cpants->files(\@files);
    $cpants->dirs(\@files);

    # find symlinks / bad_permissions
    my (@symlinks,@bad_permissions);
    foreach my $f (@dirs,@files) {
	my $p=catfile($testdir,$f);
	if (-l $f) {
	    push(@symlinks,$f);
	}
	unless (-r _ && -w _) {
	    push(@bad_permissions,$f);
	}
    }

    # store stuff
    $cpants->{metric}{files}{list_files}=\@files;
    $cpants->{metric}{files}{list_dirs}=\@dirs;
    $cpants->{metric}{files}{list_symlinks}=\@symlinks;
    $cpants->{metric}{files}{list_bad_permissions}=\@bad_permissions;

    $cpants->{metric}{files}{count_files}=scalar @files;
    $cpants->{metric}{files}{count_dirs}=scalar @dirs;
    $cpants->{metric}{files}{count_symlinks}=scalar @symlinks;
    $cpants->{metric}{files}{count_bad_permissions}=scalar @bad_permissions;

    # find special files
    my %reqfiles;
    my @special_files=(qw(Makefile.PL Build.PL README META.yml SIGNATURE MANIFEST NINJA));
    foreach my $file (@special_files){
	(my $db_file=$file)=~s/\./_/g;
	$db_file=lc($db_file);
	$cpants->{metric}{files}{$db_file}=((grep {$_ eq "$file"} @files)?1:0);
    }

    # find modules names
    # /lib/.*.pm    -> Foo/Bar.pm -> Foo::Bar
    # bzw /.*.pm    -> Bar.pm     -> distname

}

#-----------------------------------------------------------------
# get_files
#-----------------------------------------------------------------
sub get_files {
    return if /^\.+$/;

    if (-d $_) {
	push (@dirs,$File::Find::name);
    } elsif (-f $_) {
	push (@files,$File::Find::name);
	$size+=-s _ || 0;
    }

}

##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions
  ([
    {
     name=>'has_readme',
     type=>'basic',
     error=>q{The file 'README' is missing from this distribution. The README provide some basic information to users prior to downloading and unpacking the distribution.},
     code=>sub { shift->{files}{readme} ? 1 : 0 },
    },
    {
     name=>'has_manifest',
     type=>'basic',
     error=>q{The file 'MANIFEST' is missing from this distribution. The MANIFEST lists all files included in the distribution.},
     code=>sub { shift->{files}{manifest} ? 1 : 0 },
    },
    {
     name=>'has_meta_yml',
     type=>'basic',
     error=>q{The file 'META.yml' is missing from this distribution. META.yml is needed by people maintaining module collections (like CPAN), for people writing installation tools, or just people who want to know some stuff about a distribution before downloading it.},
     code=>sub { shift->{files}{meta_yml} ? 1 : 0 },
    },
    {
     name=>'has_buildtool',
     type=>'basic',
     error=>q{Makefile.PL and/or Build.PL are missing. This makes installing this distribution hard for humans and impossible for automated tools like CPAN/CPANPLUS},
     code=>sub {
	 my $m=shift;
	 return 1 if $m->{files}{makefile_pl} || $m->{files}{build_pl};
	 return 0;
     },
    },
    {
     name=>'no_symlinks',
     type=>'basic',
     error=>q{This distribution includes symbolic links (symlinks). This is bad, because there are operating systems do not handle symlinks.},
     code=>sub {shift->{files}{count_symlinks} ? 0 : 1},
    },


# this might not be a good metric - at least according to feedback
#    {
#     name=>'permissions_ok',
#     type=>'basic',
#     error=>q{This distribution includes files with bad permissions (i.e that are not read- and writable by the user). This makes removing the extracted distribution hard.},
#     code=>sub { shift->{files}{count_bad_permissions} ? 0 : 1 },
#    },


   ]);



##################################################################
# DB
##################################################################

sub create_db {
    return
[
"create table files (
  dist varchar(150),
  count_files int unsigned default 0,
  count_dirs int unsigned default 0,
  count_symlinks int unsigned default 0,
  count_bad_permissions int unsigned default 0,
  list_files text,
  list_dirs text,
  list_symlinks text,
  list_bad_permissions text,
  makefile_pl tinyint unsigned not null default 0,
  build_pl tinyint unsigned not null default 0,
  readme tinyint unsigned not null default 0,
  manifest tinyint unsigned not null default 0,
  meta_yml tinyint unsigned not null default 0,
  signature tinyint unsigned not null default 0,
  ninja tinyint unsigned not null default 0

)",
"CREATE INDEX file_dist_idx on files (dist)"
];
}

1;


__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Files - check various files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

based on work by Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Module::CPANTS::Generator::Files is Copyright (c) 2003,2004 Thomas
Klausner, ZSI.  All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.


=cut

