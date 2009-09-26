use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 3 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

ok($mech->get('http://localhost/test.example/not_existing')->code == 404, 'test the 404 response');

$mech->get_ok('http://localhost/test.example/manage');
