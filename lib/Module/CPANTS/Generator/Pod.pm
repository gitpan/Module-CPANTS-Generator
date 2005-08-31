package Module::CPANTS::Generator::Pod;
use warnings;
use strict;
use Pod::Simple::Checker;
use File::Spec::Functions qw(catfile);


sub order { 100 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $dist=shift;
    
    my $files=$dist->files_array;
    my $testdir=$dist->testdir;

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
    $dist->pod_errors($pod_errors);
}


##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'no_pod_errors',
            error=>q{The documentation for this distribution contains syntactic errors in its POD.},
            code=>sub { shift->pod_errors ? 0 : 1 },
        },
    ];
}


##################################################################
# DB
##################################################################

sub schema {
    return {
        dist=>['pod_errors integer'],
    };
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

