#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Mail::GUI::Curses' );
}

diag( "Testing ZConf::Mail::GUI::Curses $ZConf::Mail::GUI::Curses::VERSION, Perl $], $^X" );
