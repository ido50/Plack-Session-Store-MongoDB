#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Session::Store::MongoDB' ) || print "Bail out!
";
}

diag( "Testing Plack::Session::Store::MongoDB $Plack::Session::Store::MongoDB::VERSION, Perl $], $^X" );
