package Module::CPANTS::Generator::Prereq;
use warnings;
use strict;
use base 'Module::CPANTS::Generator';

use vars(qw(%kwalitee));


sub generate {
    my $class=shift;
    my $metric=shift;

    my $k=0;
    my $files=$metric->files;
    my $prereq_file;

    if (grep {/Makefile\.PL$/} @$files) {
	$prereq_file='Makefile.PL';
    }
    if (grep {/Build\.PL$/} @$files) {
	$prereq_file='Build.PL';
    }

    return unless $prereq_file;

    open(IN,$prereq_file);
    my $m = join '', <IN>;
    close IN;

    my $p;
    if ($prereq_file eq 'Makefile.PL') {
	$p = $1 if $m =~ m/PREREQ_PM.*?=>.*?\{(.*?)\}/s;
    } elsif ($prereq_file eq 'Build.PL') {
	$p = $1 if $m =~ m/requires.*?=>.*?\{(.*?)\}/s;
    }
    return unless $p;

    # get rid of lines which are only comments
    $p = join "\n", grep { $_ !~ /^\s*#/ } split "\n", $p;
    # get rid of empty lines
    $p = join "\n", grep { $_ !~ /^\s*$/ } split "\n", $p;

    if ($p =~ /=>/ or $p =~ /,/) {
	my $prereqs;

	my $code = "{no strict; \$prereqs = { $p\n}}";
	eval $code;

	my @prereq;
	while (my ($module,$version)=each%$prereqs) {
	    push(@prereq,{
			  requires=>$module,
			  version=>$version,
			 });
	}
	$metric->add(prereq=>\@prereq);
    }
}


sub create_db {
    return
[
"create table prereq (
  dist varchar(150),
  requires varchar(150),
  version varchar(25)
)",
"CREATE INDEX prereq_dist_idx on prereq (dist)"
];
}


1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Prereq - parse PREREQ_PM and requires (Build.PL)

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

