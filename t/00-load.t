#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::RepositoryLinkPL' ) || print "Bail out!\n";
}

diag( "Testing App::RepositoryLinkPL $App::RepositoryLinkPL::VERSION, Perl $], $^X" );
