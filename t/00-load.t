#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Mail' );
	use_ok( 'ZConf::Mail::GUI' );
	use_ok( 'ZConf::Mail::GUI::Curses' );
}

diag( "Testing ZConf::Mail $ZConf::Mail::VERSION, Perl $], $^X" );
