package Module::CPANTS::Metrics;
use strict;
use warnings;
use base 'Class::Accessor';
use Carp;

use vars qw($VERSION);
$VERSION = "0.011";

my $class=__PACKAGE__;
$class->mk_accessors(qw(dist cpants data files distnameinfo error unpacked kwalitee flaws));

sub new {
    my $class=shift;
    my $cpants=shift;
    my $self=bless {},$class;
    $self->data({});
    $self->flaws([]);
    $self->cpants($cpants);
    $self->kwalitee(0);
    return $self;
}


sub add {
    my $self=shift;
    my %to_add=@_;
    my $data=$self->data;

    while (my ($key,$val)=each(%to_add)) {
	my $ref=ref($val);
	if (!$ref || $ref eq 'SCALAR') {
	    $data->{$key}=$val;
	} elsif ($ref eq 'ARRAY') {
	    my $old=$data->{$key} || [];
	    push(@$old,@$val);
	    $data->{$key}=$old;
	} elsif ($ref eq 'HASH') {
	    foreach (keys %$val) {
		$data->{$key}->{$_}=$val->{$_};
	    }
	} else {
	    die "Cannot handle $ref";
	}
    }
    return;
}


sub report {
    my $self=shift;

    # calc kwalitee
    my $total=$self->cpants->total_kwalitee;
    my $k=$self->kwalitee;
    my $rel_k=$k / $total;
    $self->add(
	       kwalitee=>$rel_k,
	       kwalitee_abs=>$k."/".$total,
	      );

    my $reporter=$self->cpants->reporter;
    foreach my $rep (@$reporter) {
	$rep->report($self);
    }
}


sub note {
    croak("do not pass more than object and two args (maybe you passed an array instead of a boolen value)") if @_>3;
    my $self=shift;
    my $check=shift;
    croak("value to check must be boolean") if ref $check;
    my $testid=shift;
    my $test=$self->cpants->kwalitee_defs->{$testid};

    if ($check) {
	my $k=$self->kwalitee;
	$k+=$test->{k};
	$self->kwalitee($k);
    } else {
	$self->add_flaw($testid);
    }
    return;
}

sub add_flaw {
    my $self=shift;
    my $flaw=shift;
    push(@{$self->{flaws}},$flaw);
    return;
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Metrics - Metric object for CPANTS data

=head1 SYNOPSIS

  my $metric=$cpants->unpack($path_to_package);

  $metric->add(version=>'1.42');
  $metric->add(size=>{packed=>1234,unpacked=>12345});
  $metric->add(prereq=>[
                        {requires=>'Foo::Bar',version=>'0.25'},
                        {requires=>'Baz',version=>'0'},
                       ]);

Or, all in one call:

  $metric->add(version=>'1.42',
               size=>{packed=>1234,unpacked=>12345},
               prereq=>[
                        {requires=>'Foo::Bar',version=>'0.25'},
                        {requires=>'Baz',version=>'0'},
                       ]);

  $metric->report;

=head1 DESCRIPTION

C<Module::CPANTS::Metrics> objects store information gathered by
CPANTS. Those objects are used by C<Module::CPANTS::Reporter>
subclasses to report the information in various ways

Each Metric objects represents one package.

=head1 METHODS

=head2 Main Methods

=head3 new

Initiate a new C<Module::CPANTS::Metrics>

Takes a C<Module::CPANTS::Generator> object as an argument, which is
available later through $metric->cpants.

C<new> is usually called from L<Module::CPANTS::Generate>s L<unpack>

=head3 add

  $metric->add(%data);

Add data to the metric object.

Data must be a plain hash, i.e. not a HASREF.

Depending on the value-type of each key, C<add> behaves differently.

=over

=item *

If the value is a SCALAR or a SCALARREF, the key and value are added
to the Metric objects data. Duplicate occurances of the same keyword
will overwrite old values.

=item *

If the value is an ARRAYREF, the values of the array will be push'ed
onto the array referenced by the keyword.

=item *

If the value is a HASHREF, the contents of this hash will be added to
the hash referenced by the keyword.

=item *

Other value types result in an error.

=back

Please note that the generated data structure is used by
L<Module::CPANTS::Reporter> subclasses to generate meaningfull
output. See L<Module::CPANTS::Reporter::DB> for a discussion on how
this data structure is dumped to a SQL database

=head3 report

Calculate total and relative kwalitee for the package.

Afterwards, for each loaded L<Module::CPANTS::Reporter> subclass, call
it's C<report> method, passing the Metrics object as an argument.


=head3 note

  $metric->note($test_value,$kwalitee_definition);

C<note> is called from L<Module::CPANTS::Generator> subclasses to add
kwalitee or a flaw.

C<$test_value> is a boolean value. C<$kwalitee_definition> a key in
the global kwalitee definition, e.g. 'no_version'.

If C<$test_value> is true, than the kwalitee provided by this test
will be added to the total kwalitee.

If C<$test_value> is false, this kwalitee definition will be stored in
the L<flaws>-array of the Metrics object.

=head3 add_flaw

Convient method to add a flaw to the list of flaws. Most of the time
you should use L<note> instead.

=head2 Accessor Methods provided by Class::Accessor

=head3 cpants

L<Module::CPANTS::Generator> object

=head3 distnameinfo

L<CPAN::DistnameInfo> object

=head3 dist

The name of the distribution, as returned by
CPAN::DistnameInfo->distvname, i.e.: C<Foo-Bar-1.43>. This is the
unique indentifier used throughout CPANTS

=head3 data

The data-hash (where L<add> stores its values)

=head3 files

ARRAYREF of all files in the distribution.

=head3 unpacked

Path to unpacked distribution

=head3 kwalitee

Current kwalitee. Makes most sense after all test are run.

=head3 flaws

ARRAYREF of the list of flaws

=head3 error

Set to a true value if an error occured during unpacking.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 COPYRIGHT

Module::CPANTS::Metrics is Copyright (c) 2003 Thomas Klausner, ZSI.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
