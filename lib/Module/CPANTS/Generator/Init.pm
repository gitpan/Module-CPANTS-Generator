package Module::CPANTS::Generator::Init;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';
use File::Find;
use File::stat;

use vars qw($VERSION);
$VERSION = "0.011";

use vars(qw(%kwalitee @files $size));

%kwalitee=
  (
   extracts_badly=>
   [q{Doesn't extact nicely.},
    q{This package doesn't create a directory and extracts its content into this directory. Instead, it spews its content into the current directory, making it really hard/annoying to remove the unpacked package.},
   ],

   no_version=>
   [q{No version number in package filename.},
    "The package filename (eg. Foo-Bar-1.42.tar.gz) does not include a version number (or something that looks like a reasonable version number to CPAN::DistnameInfo)",
   ],

   unknown_package_type=>
   [q{Unknown package type).},
    q{This package uses an unknown packageing format. CPANTS can handle tar.gz, tgz and zip archives.},
    0,
   ],

  );


sub generate {
    my $class=shift;
    my $metric=shift;

    our @files=();
    our $size=0;
    find(\&get_files,'.');
    $metric->files(\@files);
    $metric->add(size=>{unpacked=>$size});

    $metric->note($metric->data->{files}{extracts_nicely},
		  'extracts_badly');

    $metric->note($metric->data->{version},'no_version');

    return;
}

sub create_db {
    return
[
"create table cpants (
  dist varchar(150),
  package varchar(150),
  version varchar(50),
  version_major bigint,
  version_minor varchar(30),
  extension varchar(25),
  extracts_nicely tinyint unsigned not null default 0,
  cpan_author varchar(15),
  description varchar(100),
  kwalitee float,
  kwalitee_abs varchar(50),
  date_release datetime,
  run varchar(20)
)",
"CREATE INDEX cpants_dist_idx on cpants (dist)",
"CREATE INDEX cpants_run_idx on cpants (run)",

"create table size (
  dist varchar(150),
  packed bigint default 0,
  unpacked bigint default 0
)",
"CREATE INDEX size_dist_idx on size (dist)"
];
}

sub get_files {
    return if /^\.+$/;
    push (@files,$File::Find::name);
    $size+=-s $_ || 0;
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Init - basic tests

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
