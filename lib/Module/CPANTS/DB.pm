package Module::CPANTS::DB;
use strict;
use warnings;
use Carp;
use Cwd;

use base 'Class::DBI::SQLite';
use Class::DBI::Pager;
use Module::CPANTS::Config;
my $conf=Module::CPANTS::Config->new;

__PACKAGE__->set_db('Main',"dbi:SQLite:dbname=".$conf->db_file);

package Module::CPANTS::DB::Dist;
use base 'Module::CPANTS::DB';
__PACKAGE__->columns(TEMP=>qw(from testfile testdir files_array dirs_array pauseid));
__PACKAGE__->has_many(modules=>'Module::CPANTS::DB::Modules'=>'dist');
__PACKAGE__->has_many(uses=>'Module::CPANTS::DB::Uses'=>'dist');
__PACKAGE__->has_many(prereqs=>'Module::CPANTS::DB::Prereq'=>'dist');

__PACKAGE__->set_up_table('dist');
__PACKAGE__->has_a(kwalitee=>'Module::CPANTS::DB::Kwalitee');
__PACKAGE__->has_a(author=>'Module::CPANTS::DB::Author');

__PACKAGE__->add_constructor(retrieve_dist=>'dist_without_version=?');


__PACKAGE__->set_sql(required_by_otherauthor=>
    "SELECT prereq.dist as id FROM prereq,author,dist
    WHERE dist.author=author.id AND dist.id=prereq.dist
    AND prereq.in_dist=? AND author.pauseid != ?"
);
__PACKAGE__->set_sql(required_by=>
    "SELECT DISTINCT dist as id FROM prereq
    WHERE in_dist=?"
);

__PACKAGE__->set_sql(best_dists=>
    "SELECT dist.id FROM dist,kwalitee,author where dist.kwalitee=kwalitee.id AND kwalitee.kwalitee=? AND dist.author=author.id order by author.pauseid"
);
__PACKAGE__->set_sql(worst_dists=>
    "SELECT dist.id FROM dist,kwalitee,author where dist.kwalitee=kwalitee.id AND kwalitee.kwalitee<5 AND dist.author=author.id order by kwalitee.kwalitee,author.pauseid"
);


sub uses_in_tests {
    my $self=shift;
    return Module::CPANTS::DB::Uses->search_in_tests($self->id);
}   
sub uses_in_code {
    my $self=shift;
    return Module::CPANTS::DB::Uses->search_in_code($self->id);
}   

package Module::CPANTS::DB::Kwalitee;
use base 'Module::CPANTS::DB';
__PACKAGE__->set_up_table('kwalitee');
__PACKAGE__->has_many(dist=>'Module::CPANTS::DB::Dist'=>'kwalitee');

package Module::CPANTS::DB::Modules;
use base 'Module::CPANTS::DB';
__PACKAGE__->set_up_table('modules');
__PACKAGE__->has_a(dist=>'Module::CPANTS::DB::Dist');

package Module::CPANTS::DB::Uses;
use base 'Module::CPANTS::DB';
__PACKAGE__->set_up_table('uses');
__PACKAGE__->has_a(dist=>'Module::CPANTS::DB::Dist');
__PACKAGE__->has_a(in_dist=>'Module::CPANTS::DB::Dist');
__PACKAGE__->set_sql(in_tests=>"SELECT uses.id FROM uses where uses.dist=? AND in_tests>0 order by uses.module");
__PACKAGE__->set_sql(in_code=>"SELECT uses.id FROM uses where uses.dist=? AND in_code>0 order by uses.module");

package Module::CPANTS::DB::Prereq;
use base 'Module::CPANTS::DB';
__PACKAGE__->set_up_table('prereq');
__PACKAGE__->has_a(dist=>'Module::CPANTS::DB::Dist');

package Module::CPANTS::DB::Author;
use base 'Module::CPANTS::DB';
__PACKAGE__->set_up_table('author');
__PACKAGE__->has_many(dists=>'Module::CPANTS::DB::Dist'=>'author');
__PACKAGE__->add_constructor(retrieve_author=>'pauseid=?');
__PACKAGE__->add_constructor(top40_many=>"num_dists>=5 order by average_kwalitee desc,num_dists desc,pauseid");
__PACKAGE__->add_constructor(top40_few=>"num_dists<5 AND num_dists>0 order by average_kwalitee desc,num_dists desc,pauseid");

1;

__END__


