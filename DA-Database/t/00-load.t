#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DA::Database' ) || print "Bail out!\n";
}

diag( "Testing DA::Database $DA::Database::VERSION, Perl $], $^X" );
