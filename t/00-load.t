#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Padre::Plugin::PPIExplorer' ) || print "Bail out!
";
}

diag( "Testing Padre::Plugin::PPIExplorer $Padre::Plugin::PPIExplorer::VERSION, Perl $], $^X" );
