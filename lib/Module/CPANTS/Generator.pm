package Module::CPANTS::Generator;
use Carp;
use Cwd;
use Storable;
use Data::Dumper;
use base qw(Class::Accessor);
use File::Copy;
use File::Path;
use File::Spec::Functions (':ALL');
use CPAN::DistnameInfo;
use AppConfig qw(:expand :argcount);

use Module::CPANTS::Metrics;

use strict;
use warnings;

use vars qw($VERSION $run_id $kwalitee_defs);
$VERSION = "0.010";

Module::CPANTS::Generator->mk_accessors
  (qw(conf total_kwalitee tests reporter));

sub new {
    my $class=shift;
    my $opts=shift;

    my $self=bless {},$class;

    my $config=AppConfig->new();
    $config->define
      (qw(quiet force reload_cpan),
       qw(cpan=s limit=s),
       'temp_dir=s'=>{DEFAULT=>catdir($FindBin::Bin,'temp')},
       'unpack_dir=s'=>{DEFAULT=>catdir($FindBin::Bin,'unpacked')},
       qw(reporter=s@ dbi_connect=s@),
       'tests=s@'=>{DEFAULT=>['Init']},
      );

    $config->file("$FindBin::Bin/.cpants");
    $config->args;

    $self->conf($config);

    # load tests & reporter
    $self->load_tests;
    $self->load_reporter;

    return $self;
}


sub load_tests {
    my $self=shift;
    my $tests=$self->conf->tests;
    my $total_kwalitee;
    print "Loading Test Modules\n" unless $self->conf->quiet;

    no strict 'refs';

    foreach my $test (@$tests) {
	$test="Module::CPANTS::Generator::$test";
	eval "require $test";
	croak "cannot load $test: $@\n" if $@;
	print "+ loaded $test\n" unless $self->conf->quiet;

	my $local_k_def=$test."::kwalitee";
	while(my($def,$info)=each %$local_k_def) {
	    croak "duplicate test definition: $def in $test\n" if $kwalitee_defs->{$def};
	    $kwalitee_defs->{$def}=
	      {
	       short=>$info->[0],
	       long=>$info->[1] || "no long descriptio, here is the short one: ".$info->[0],
	       k=>$info->[2] || 1,
	       class=>$test,
	      };
	    $total_kwalitee+=$info->[2] || 1;
	}
    }
    $self->total_kwalitee($total_kwalitee);
    print "Total Kwalitee available: $total_kwalitee\n" unless $self->conf->quiet;

    $self->tests($tests);
    return;
}



sub load_reporter {
    my $self=shift;
    my $reporter=$self->conf->reporter;
    print "Loading Reporter Modules\n" unless $self->conf->quiet;

    foreach my $rep (@$reporter) {
	$rep="Module::CPANTS::Reporter::$rep";
	eval "require $rep";
	croak "cannot load $rep: $@\n" if $@;
	$rep->init($self);
	print "+ loaded $rep\n" unless $self->conf->quiet;
    }
    $self->reporter($reporter);
    return;
}

sub unpack {
    my $self=shift;
    my $path=shift;   # path ist absolut (weil CPANPLUS ->fetched) !! SHIT!
    my $temp_dir=$self->conf->temp_dir;
    my $unpack_dir=$self->conf->unpack_dir;

    my $metric=Module::CPANTS::Metrics->new($self);

    if (!-e $temp_dir) {
	mkdir($temp_dir) || die "ERROR $!";
    }
    chdir($temp_dir);

    my $di=CPAN::DistnameInfo->new($path);
    $metric->distnameinfo($di);
    $metric->dist($di->distvname);

    print "+ ".$di->filename."\n";

    my $size_packed=-s $path;

    # extract
#    my $ext=$di->archive_extn;
    my $ext=$di->extension;
    if ($ext eq 'tar.gz' || $ext eq 'tgz') {
	system("tar", "xzf", $path);
    } elsif ($ext eq 'zip') {
	system("unzip", "-q", $path);
    } else {
	$metric->add(
		     package=>$di->filename,
		     kwalitee=>0,
		     kwalitee_abs=>"0/".$self->total_kwalitee,
		    );
	$metric->error("unknown package format: ",$di->filename,", skipping test of package\n");
	return $metric;
    }

    # check if package is polite
    opendir(DIR,".");
    my @stuff=grep {/\w/} readdir(DIR);
    closedir DIR;

    my $target;
    my $extracts_nicely=0;
    if (@stuff == 1) {
	# tempdir containts one thing, so move it
	$extracts_nicely=1;
	$target=catdir($unpack_dir,$stuff[0]);
	if (-e $target) {
	    # hmm, extraction happend allready, we're skipping moving
	    # but skipping extraction might be a better idea...
	    print "\tpackage allready unpacked, skipping extraction\n";
	    rmtree $stuff[0] || die "ERROR $!";
	} else {
	    move($stuff[0],$target) || die "ERROR $!";
	}

    } else {
	# not a proper tarball...
	print "\tnot a proper tarball\n";
	my $fakedir=$di->distvname;
 	$target=catdir($unpack_dir,$fakedir);
	if (-e $target) {
	    print "\tpackage allready unpacked, skipping extration\n";
	    rmtree $temp_dir || die "ERROR $!";
	} else {
	    mkdir($target) || die "ERROR $!";
	    print "\tmove to $target\n";
	    move($temp_dir,$target) || die "ERROR $!";
	}
    }

    my ($major,$minor)=$di->version=~/^(\d+)\.(.*)/;
    $major||=$di->dist;

    $metric->unpacked($target);
    $metric->add
      (
       package=>$di->filename,
       extension=>$ext,
       version=>$di->version,
       version_major=>$major,
       version_minor=>$minor,
       files=>{extracts_nicely=>$extracts_nicely},
       size=>{packed=>$size_packed},
      );
    return $metric;
}


sub unpack_cpanplus {
    my $self=shift;
    my $module=shift;

    my $temp_dir=$self->conf->temp_dir;
    my $unpack_dir=$self->conf->unpack_dir;

    # fetch
    my $f=$module->fetch;

    my $metric=$self->unpack($f);
    $metric->add(cpan_author=>$module->author);
    return $metric;
}


sub run_id {
    return $run_id if $run_id;

    my ($d,$m,$y)=(localtime)[3,4,5];
    $run_id=sprintf("%04d%02d%02d",$y+1900,$m+1,$d);
    return $run_id;
}

sub kwalitee_defs {
    return $kwalitee_defs;
}

sub create_db {
    croak("Method 'create_db' must be implemented in subclass");
}

sub generate {
    croak("Method 'generate' must be implemented in subclass");
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator - Generate CPANTS statistics

=head1 SYNOPSIS

  my $cpants=Module::CPANTS::Generator->new;
  
  my $metric=$cpants->unpack($path_to_package);
  
  foreach my $testclass (@test_classes) {
      print "\trunning $testclass\n";
      $testclass->generate($metric);
  }
  
  $metric->report;

Or see examples/*.pl for some scripts

=head1 DESCRIPTION

C<Module::CPANTS::Generator> is BETA code, so things might change
in future releases.

Please note that CPAN::DistnameInfo Version 0.04 is needed, which is not
released yet. You can get it from here:
http://svn.mutatus.co.uk/browse/CPAN-DistnameInfo/trunk/

CPANTS consists of three basic classes, some of which require
subclassing to work. There is one main object, $cpants (provided by
Module::CPANTS::Generator), and one object for each distribution that
is tested called $metric (provided by
Module::CPANTS::Metrics). Module::CPANTS::Reporter does not create
objects but uses class methods.

First, a Module:CPANTS:Generator object is created, called C<$cpants>
It contains a configuration object (AppConfig) and is responsible for
loading testing and reporting modules. It might use a
CPANPLUS::Backend to connect to CPAN.

Each testing module (which must be a subclass of
Module:CPANTS:Generator) contains information on the tests it is going
to run. From this information, $cpants calculates the total kwalitee
available and generates some metadata (which test are there, what
exaclty do they test).

While testing each distribution, a Metrics Object for this
distribution is created. This object contains information on the
distribution (name, unpacked location, etc), a link to the C<$cpants>
object (to access config values etc) and a data structure of the test
results.

During and after testing, all loaded reporter modules (subclasses of
L<M:C:Reporter>) are called.


=head1 CONFIGURATION

Module:CPANTS:Generator uses AppConfig for reading command line
options and config files.

From the commandline, use

  -option value

In a config file, use

  option = value

See L<AppConfig> for detailed information.

Here is a list of options:

Please note that all CPAN-releated config values are only needed if
you want to test distributions on CPAN and thus are not needed in
"lint"-mode.

=head2 Boolean values

=head3 quiet

Supress output

Default: undef

=head3 force

Force testing of all distributions reported by CPANPLUS (instead of
only testing previously untested distributions)

Default: undef

=head3 reload_cpan

Call C<reload_indices> on the CPANPLUS::Backend object. This will
establish a connection to your CPAN mirror and fetch a new filelist.

Default: undef

=head2 String values

=head3 temp_dir

Path to a temp directory. This shouldn't be /tmp, but a custom temp
directory only used by CPANTS (as it might be deleted)

Default: catdir($FindBin::Bin,'temp')

=head3 unpack_dir

Path to a directory where all unpacked distributions will be
stored. This should be on a big enough disk to handle about 3 Gigs.

Default: catdir($FindBin::Bin,'unpacked')

=head3 cpan

Path to a local CPAN mirror. I hope nobody is crazy enough to use
CPANTS over the network.

Default: undef

=head3 limit

Maximum number of distributions to test. Mainly usefull when
developing new tests to limit running time.

Default: undef

=head2 List values

=head3 reporter

A list of L<Module::CPANTS::Reporter> subclasses. Do not include
"Module::CPANTS::Reporter" here, it will be appended when the reporter
modules are loaded.

You should add at least one Reporter module, or else you'll spend some
CPU cycles for nothing...

Default: undef

=head3 tests

A list of L<Module::CPANTS::Generator> subclasses. Do not include
"Module::CPANTS::Generator" here, it will be appended when the test
modules are loaded.

Add or remove tests as you wish, but keep the C<Init>-test active, or
else strange things might happen.

It's very handy to only load those testing modules you're currently
developing.

Default: ['Init']

=head3 dbi_connect

DBI connect information (data source, username, password). This array
will be passed as-is to L<DBI>s C<connect> method.

Default: undef

=head1 METHODS

=head2 Main Methods

=head3 new

Initiate a new cpants object. Configuration is set up using AppConfig.

C<new> calls L<load_tests> and L<load_reporter> after setting up the
object.

=head3 load_tests

Load testing modules. Called by L<new>, so do not call it directly.

The config value L<reporter> contains a list of testing module
names. 'Module::CPANTS::Generator::' will be prepended to each module
name. (eg. 'Files' is changed to 'Module::CPANTS::Generator::Files'

Each module is loaded. Each's module package global hash C<%kwalitee>
is used to generate the global kwalitee definitions and to calculate the
total kwalitee available.

=head3 load_reporter

Load reporter modules. Called by L<new>, so do not call it directly.

The config value L<reporter> contains a list of reporter module
names. 'Module::CPANTS::Reporter::' will be prepended to each module
name. (eg. 'DB' is changed to 'Module::CPANTS::Reporter::DB'

Each module is loaded and the class method C<init> called.

=head3 unpack

  my $metric=$cpants->unpack($path_to_package);

Unpack does quite a lot:

=over

=item *

initiate a new L<Module::CPANTS::Metrics> object for the to be tested
package.

=item *

initate a new CPAN::DistnameInfo object from the package filename.

=item *

extract the package

=item *

check if the package extracts nicely

=item *

move the extracted package to L<unpack_dir>

=item *

add some first information (size_packed, extracts_nicely, data
provided by CPAN::DistnameInfo) to the metrics object

=back

Returns a L<Module::CPANTS::Metrics> object.

=head3 unpack_cpanplus

  my $metric=$cpants->unpack_cpanplus($module_object);

Wrapper around L<unpack>.

C<$module_object> must be a CPANPLUS module object.

C<unpack_cpanplus> will use CPANPLUS::Backend to fetch the package
from CPAN (hopefully from a local mirror) and call L<unpack> on it.

Additionally, $metric->cpan_author will be set to the value of
$module_object->author.

=head2 Virtual Methods

These Methods must be implemented in subclasse of
C<Module::CPANTS::Generator>

=head3 generate

This method does the actual testing and generating of data. See
L<Module::CPANTS::Generator::Init> and
L<Module::CPANTS::Generator::Files> for more info / examples.

=head3 create_db

Return a ARRAYREF containing SQL-statments to create tables that can
store all information generated by the module.

=head2 Accessor Methods provided by Class::Accessor

=head3 conf

Return the AppConfig object.

You can do $cpants->conf->config_key to access config values directly.

=head3 total_kwalitee

return total wwalitee.

=head3 tests

Return arrayref of loaded test modules (Subclasses of
Module::CPANTS::Generator). This are the fully qualified namespaces,
i.e. C<Module::CPANTS::Generator::Prereq>

=head3 reporter

Return arrayref of loaded reporter modules (Subclasses of
Module::CPANTS::Reporter). This are the fully qualified namespaces,
i.e. C<Module::CPANTS::Reporter::DB>)


=head1 CPANTS

The CPAN Testing Service.

See http://www.pobox.com/~schwern/talks/CPANTS/full_slides/
and http://domm.zsi.at/talks/vienna_pm200309/ for more info.

=head1 SEE ALSO

Module::CPANTS::Metrics

Module::CPANTS::Reporter

=head1 TODO

=over

=item * More Tests

=item * Better Tests

=back

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

Please use the perl-qa mailing list for discussing all things CPANTS:
http://lists.perl.org/showlist.cgi?name=perl-qa

based on work by Leon Brocard <acme@astray.com> and the original idea
proposed by Michael G. Schwern <schwern@pobox.com>

=head1 LICENSE

Module::CPANTS::Generator is Copyright (c) 2003 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
