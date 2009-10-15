use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 14 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok('http://localhost/test.example/index.html');

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
$mech->content_like(qr(http://localhost/instances/test.example/static/css/styles.css), 'Stylesheet URI correct');

$mech->get_ok('http://localhost/test.example/', 'URI without index.html works');

# test INSTANCE environment var
$ENV{CIDERCMS_INSTANCE} = 'test.example';

$mech->get_ok('http://localhost/index.html');

$mech->title_like(qr/Testsite/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
$mech->content_like(qr(http://localhost/static/css/styles.css), 'Stylesheet URI correct');

$mech->get_ok('http://localhost/', 'short URI without index.html works');

# beef up our layout
system ('/bin/cp', "$Bin/test.example/index.zpt", "$Bin/../root/instances/test.example/templates");

$mech->get_ok('http://localhost/', 'new layout works');
$mech->follow_link_ok({ url_regex => qr(folder_1) });

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 1 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->ok('id("subnav")', 'subnav found');
}
