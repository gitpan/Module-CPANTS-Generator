package Module::CPANTS::Generator::Pod;
use strict;
use File::Find::Rule;
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';

sub generate {
    my $self = shift;

    my $cpants = $self->grab_cpants;

    foreach my $dist (sort grep { -d } <*>) {
        next if $dist =~ /^\./;
        print "* $dist *\n";
        my ($lines, $pod) = (0, 0);
        for my $file (find( file => name => '*.{pod,pm}', in => $dist )) {
            open my $fh, "$file" or next;
            # worlds stupidest pod parser - incorrect but quick
            my $inpod;
            while (<$fh>) {
                /^=/     and $inpod = 1;
                /^=cut$/ and $inpod = 0;
                $pod++ if $inpod;
                $lines++;
            }
        }
        $cpants->{ $dist }{lines} = { total  => $lines,
                                      pod    => $pod,
                                      nonpod => $lines - $pod };
    }
    $self->save_cpants( $cpants );
}

1;

