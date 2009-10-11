use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 10 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/index.html' );

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
$mech->content_like(qr(http://localhost/instances/test.example/static/css/styles.css), 'Stylesheet URI correct');

$mech->get_ok('http://localhost/test.example/', 'URI without index.html works');

# test INSTANCE environment var
$ENV{CIDERCMS_INSTANCE} = 'test.example';

$mech->get_ok( 'http://localhost/index.html' );

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
$mech->content_like(qr(http://localhost/static/css/styles.css), 'Stylesheet URI correct');
