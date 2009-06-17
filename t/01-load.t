#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Mail::GUI' );
}

diag( "Testing ZConf::Mail::GUI $ZConf::Mail::GUI::VERSION, Perl $], $^X" );
