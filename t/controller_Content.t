use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 7 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok('http://localhost/test.example/index.html');

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
my $styles = $mech->find_link(url_regex  => qr{styles.css});
$mech->links_ok([ $styles ]);

$mech->get_ok('http://localhost/test.example/', 'URI without index.html works');

# images work
my $image = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($image->url);
