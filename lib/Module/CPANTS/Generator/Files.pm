package Module::CPANTS::Generator::Files;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';

use vars(qw(%kwalitee));

%kwalitee=
  (
   has_symlinks=>
   [q{Includes symlinks.},
    q{This distribution includes symbolic links (symlinks). This is bad, because there are operating systems do not handle symlinks.},
   ],
   has_bad_permissions=>
   [q{Includes files with bad permissions},
    q{This distribution includes files that are not read- and writable by the user. This makes removing the extracted distribution hard.},
   ],
   no_makefile=>
   [q{No Makefile.PL or Build.PL},
    q{Makefile.PL and/or Build.PL are missing. This makes installing this distribution hard for humans and impossible for automated tools like CPAN/CPANPLUS},
   ],
   no_readme=>
   [q{No README},
    q{The file 'README' is missing from this distribution. The README provide some basic information to users prior to downloading and unpacking the distribution.},
   ],
   no_manifest=>
   [q{No MANIFEST},
    q{The file 'MANIFEST' is missing from this distribution. The MANIFEST lists all files included in the distribution.},
   ],
   no_tests=>
   [q{No tests.},
    q{This distribution has no test suite. This is BAD!},
   ],

  );


sub generate {
    my $class=shift;
    my $metric=shift;

    my (@symlinks,@bad_permissions);
    my $files=$metric->files;
    foreach my $f (@$files) {
	if (-l $f) {
	    push(@symlinks,$f);
	}
	unless (-r _ && -w _) {
	    push(@bad_permissions,$f);
	}
    }

    $metric->note(scalar @symlinks,'has_symlinks');
    $metric->note(scalar @bad_permissions,'has_bad_permissions');

    my %reqfiles;
    foreach my $file (qw(Makefile.PL Build.PL configure README META.yml SIGNATURE MANIFEST test.pl t lib)) {
	(my $db_file=$file)=~s/\./_/g;
	$db_file=lc($db_file);
	$reqfiles{$db_file}=1 if (grep {$_ eq "./$file"} @$files);
    }

    $metric->note(($reqfiles{makefile_pl} || $reqfiles{build_pl}),'no_makefile');
    $metric->note($reqfiles{readme},'no_readme');
    $metric->note($reqfiles{manifest},'no_manifest');
    $metric->note(($reqfiles{t} || $reqfiles{test_pl}),'no_tests');

    # not working correct (libwin32)
#    my $num_pm_top=grep {m|^[^\/]\.pm$|} @$files;
#    ($num_pm_top == 1 || $reqfiles{lib}) ? $k++ : $metric->nit("No lib dir but more than one *.pm in top dir");

    $metric->add(files=>{
			 num_files=>scalar @$files,
			 symlinks=>scalar @symlinks,
			 list_symlinks=>join(';',@symlinks),
			 bad_permissions=>scalar @bad_permissions,
			 list_bad_permissions=>join(';',@bad_permissions),
			 %reqfiles,
			 });

}


sub create_db {
    return
[
"create table files (
  dist varchar(150),
  num_files int unsigned default 0,
  symlinks tinyint unsigned not null default 0,
  list_symlinks varchar(250),
  bad_permissions tinyint unsigned not null default 0,
  list_bad_permissions varchar(250),
  extracts_nicely tinyint unsigned not null default 0,
  makefile_pl tinyint unsigned not null default 0,
  build_pl tinyint unsigned not null default 0,
  configure tinyint unsigned not null default 0,
  readme tinyint unsigned not null default 0,
  manifest tinyint unsigned not null default 0,
  meta_yml tinyint unsigned not null default 0,
  signature tinyint unsigned not null default 0,
  test_pl tinyint unsigned not null default 0,
  t tinyint unsigned not null default 0,
  lib tinyint unsigned not null default 0
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

Module::CPANTS::Metrics is Copyright (c) 2003 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.


=cut

