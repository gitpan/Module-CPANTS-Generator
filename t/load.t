#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests=>6;


BEGIN {
    use_ok('Module::CPANTS::Generator');
    use_ok('Module::CPANTS::Generator::CPAN');
    use_ok('Module::CPANTS::Generator::Files');
    use_ok('Module::CPANTS::Generator::Unpack');
    use_ok('Module::CPANTS::Generator::Prereq');
    use_ok('Module::CPANTS::Generator::Pod');
}
