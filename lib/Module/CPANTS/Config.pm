package Module::CPANTS::Config;
use strict;
use warnings;
use File::Spec::Functions qw(catdir catfile);


sub new { return bless {},shift }

# currently hardcoded, should be settable via ./Build
sub basedir { '/home/domm/perl/Module-CPANTS-Generator/cpants/' }
sub minicpan { '/home/minicpan/' }


# config values induced from others
sub db_file { return catfile(shift->basedir,'cpants.db') }

sub minicpan_01mailrc {
    my $self=shift;
    return catfile($self->minicpan,'authors','01mailrc.txt.gz');
}

sub minicpan_02packages {
    my $self=shift;
    my $cpants=shift;
    return catfile($self->minicpan,'modules','02packages.'.($cpants->opts->{'test'}?'cpants_'.$cpants->opts->{'test'}:'details').'.txt.gz');
}

sub minicpan_path_to_dist {
    my $self=shift;
    my $prefix=shift;
    return catfile($self->minicpan,'authors','id',$prefix);
}

sub testdir {
    return catfile(shift->basedir,'testing','tmp');
}


1;

__END__


