package Module::CPANTS::Generator::Pod;
use warnings;
use strict;
use Pod::Simple::Checker;
use base 'Module::CPANTS::Generator';
use File::Spec::Functions qw(catfile);

use vars qw($VERSION);
$VERSION = "0.23";


##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $cpants=shift;
    my $files=$cpants->files;
    my $testdir=$cpants->testdir;

    my $pod_errors=0;
    foreach my $file (@$files) {
	next unless $file=~/\.p(m|od)$/;

	eval {
	    # Count the number of POD errors
	    my $parser=Pod::Simple::Checker->new;
	    my $errata;
	    $parser->output_string(\$errata);
	    $parser->parse_file(catfile($testdir,$file));
	    my $errors=()=$errata=~/Around line /g;
	    $pod_errors+=$errors;
	}
    }
    $cpants->{metric}{pod_errors}=$pod_errors;
}


##################################################################
# Kwalitee Indicators
##################################################################


__PACKAGE__->kwalitee_definitions
([
  {
   name=>'no_pod_errors',
   type=>'basic',
   error=>q{The documentation for this distribution contains syntactic errors in it's POD.},
   code=>sub { shift->{pod_errors} ? 0 : 1 },
   },
 ]);


##################################################################
# DB
##################################################################

sub sql_fields_dist {
    return "
pod_errors int,
"
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Pod - check for POD errors

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Generator::Pod is Copyright (c) 2004 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.


=cut

