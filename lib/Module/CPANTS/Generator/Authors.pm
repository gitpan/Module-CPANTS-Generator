package Module::CPANTS::Generator::Authors;
use warnings;
use strict;
use Parse::CPAN::Authors;

sub order { 100 }

sub fill_authors {
    my $self=shift;
    my $cpants=shift;
    
    print "parsing authors info\n";
    my $p = Parse::CPAN::Authors->new(Module::CPANTS::Generator->minicpan_01mailrc);
    foreach my $auth ($p->authors) {
        my $a=Module::CPANTS::DB::Author->find_or_create({pauseid=>$auth->pauseid});
        print $a->pauseid,"\n" if $cpants->opts->{verbose};
        foreach (qw(name email)) {
            $a->$_($auth->$_);
        }
        $a->update;
    }
}


##################################################################
# Analyse
##################################################################

sub analyse { 
    my $self=shift;
    my $dist=shift;
    my $pauseid=$dist->pauseid || 'UNKNOWN';
    my $author=Module::CPANTS::DB::Author->find_or_create(pauseid=>$pauseid);
    $dist->author($author);
    return 1;
}


##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators { [] }


##################################################################
# DB
##################################################################

sub schema {
    return {
        dist=>['author integer not null default 0'],
        author=>[
            'id INTEGER PRIMARY KEY',
            'pauseid text',
            'name text',
            'email text',
            'average_kwalitee integer',
            'prev_av_kw integer',
            'num_dists integer',
            'rank integer',
        ],
        index=>[
            'create index dist_auth on dist(author)',
            'create index auth_id on author(id)',
            'create index auth_pauseid on author(pauseid)',
            'create index auth_av on author(average_kwalitee)',
            'create index auth_pav on author(prev_av_kw)',
            'create index auth_num on author(num_dists)',
            'create index auth_rank on author(rank)',
        ],
    };
}

1;
__END__

=pod

=head1 NAME

Module::CPANTS::Generator::Authors - collect Authors data

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

