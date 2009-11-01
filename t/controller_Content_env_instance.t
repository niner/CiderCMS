use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

BEGIN {
    # test INSTANCE environment var
    $ENV{CIDERCMS_INSTANCE} = 'test.example';
}

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 11 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok('http://localhost/index.html');

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
my $styles = $mech->find_link(url_regex  => qr{styles.css});
$mech->links_ok([ $styles ]);

$mech->get_ok('http://localhost/', 'short URI without index.html works');

# images work
my $image = $mech->find_image(url_regex => qr{catalyst_logo.png});
$mech->get_ok($image->url);
$mech->back;

$mech->get_ok('http://localhost/', 'new layout works');
$mech->follow_link_ok({ url_regex => qr(folder_1) });

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 2 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->ok('id("subnav")', 'subnav found');

    $mech->follow_link_ok({ url_regex => qr(folder_3) });
}

