package Module::CPANTS::Reporter::DB;
use DBI;
use base 'Module::CPANTS::Reporter';
use strict;
use warnings;

use vars(qw($VERSION $DBH $tables));
$VERSION = "0.011";

sub init {
    my $class=shift;
    my $cpants=shift;
    my $dbi_connect=$cpants->conf->dbi_connect;
    $DBH=DBI->connect(@$dbi_connect);

    $DBH->do("drop table flaws");
    my $flaw_sql=$class->get_create_flaw_table($cpants);
    $DBH->do($flaw_sql);
}

sub DBH {
    return $DBH;
}

sub report {
    my $class=shift;
    my $metric=shift;

    my $data=$metric->data;
    my $tables=$class->get_tables($data);
    my $DBH=$class->DBH;

    # remove this dist from all tables
    foreach (@$tables) {
	$DBH->do("delete from $_ where dist=?",undef,$metric->dist);
    }

    # insert new data
    my @cpants_columns=qw(dist run);
    my @cpants_data=($metric->dist,Module::CPANTS::Generator->run_id);

    while (my ($k,$v)=each %$data) {
	my $ref=ref($v);
	if (!$ref || $ref eq 'STRING') {
	    $v=$$v if ref eq 'STRING';
	    push(@cpants_columns,$k);
	    push(@cpants_data,$v);

	} elsif ($ref eq 'ARRAY') {
	    foreach my $row (@$v) {
		my @columns=('dist');
		my @data=($metric->dist);
		foreach my $sk (keys %$row) {
		    push(@columns,$sk);
		    my $sval=$row->{$sk};
		    if (defined($sval)) {
			if ($sval =~ /\0/) {  # Binary Null in prereq of  Astro::Aladin not handled by SQLite
			    $sval=undef;
			}
		    }
		    push(@data,$sval);
		}
		$DBH->do("insert into $k (".join(',',@columns).") values (".join(',',map{'?'}@data).")",undef,@data);
	    }

	} elsif ($ref eq 'HASH') {
	    my @columns=('dist');
	    my @data=($metric->dist);
	    foreach my $sk (keys %$v) {
		push(@columns,$sk);
		push(@data,$v->{$sk});
	    }
	    $DBH->do("insert into $k (".join(',',@columns).") values (".join(',',map{'?'}@data).")",undef,@data);
	}
    }
    $DBH->do("insert into cpants (".join(',',@cpants_columns).") values (".join(',',map{'?'}@cpants_data).")",undef,@cpants_data);

    my @flaws=@{$metric->flaws};
    if (@flaws) {
	$DBH->do("insert into flaws (dist,".join(',',@flaws).") values (?,".join(',',map{'?'}@flaws).")",undef,$metric->dist,map{1}@flaws);
    }

    return;
}

sub finish { return }

sub get_tables {
    my $class=shift;
    my $data=shift;
    if (!$tables) {
	my @tables=(qw(cpants flaws));
	while (my ($k,$v)=each %$data) {
	    if (ref($v)) {
		push(@tables,$k);
	    }
	}
	$tables=\@tables;
    }
    return $tables;
}

sub get_create_flaw_table {
    my $class=shift;
    my $cpants=shift;

    my $kdef=$cpants->kwalitee_defs;
    my $sql="
create table flaws (
  dist varchar(150),";

    $sql.=join(",",map {"$_ tinyint not null default 0"} sort keys %$kdef);
    $sql.=")";
    return $sql;
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Reporter::DB - save metrics in a database

=head1 SYNOPSIS

see L<Module::CPANTS::Reporter>

=head1 DESCRIPTION

Module::CPANTS::Reporter::DB saves metrics into a database. Any
database system can be used, as long as there is an DBI driver
available.

You must specify the connection information in the CPANTS config file
(F<.cpants>) as an array ref.

  # in .cpants
  dbi_connect=>["dbi:mysql:cpants",'','',{RaiseError=>1}],

This array ref will be passed directly to DBI's C<connect>.

=head2 Methods

=head3 init

Connects to DB. The DBH is stored in a package global.

=head3 DBH

Returns the package-globally stored DBH.

=head3 report

Saves metrics into the DB.

As the metrics come as one big hash, the following logic is used to
split the date into different tables:

=over

=item *

If the value is a B<string>, it will be stored in table 'cpants' using
the key as the column name.

=item *

If the value is a B<hashref>, the key denotes the name of the table
to store the data. The keys and values of the hashref are used as
columns and data.

=item *

If the value is an B<arrayref>, iterate over the values of the array,
which must be hashrefs. The name of the key is again the name of the
table. For each array value (which is a hashref), the keys and values
of this hash are used as columns and data.

=back

Prior to saving the metrics, all data for the current distribution is
deleted.

=head3 finish

Not used.

=head3 get_tables

Returns a list of tables by doing an analysis of the metrics data
somewhat similar to C<report>, only simpler. This list is used to
delete old data.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at>

http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=cut

