use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 4 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/index.html' );

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
