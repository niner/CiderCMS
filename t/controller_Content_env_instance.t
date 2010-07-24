use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Image::Imlib2;

BEGIN {
    # test INSTANCE environment var
    $ENV{CIDERCMS_INSTANCE} = 'test.example';
}

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 14 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok('http://localhost/index.html');

$mech->title_is('Testsite', 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
my $styles = $mech->find_link(url_regex  => qr{styles.css});
$mech->links_ok([ $styles ]);

$mech->get_ok('http://localhost/', 'short URI without index.html works');

# images work
my $img = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($img->url);

my ($fh, $filename) = tempfile();
$mech->save_content($filename);
my $image = Image::Imlib2->load($filename);
ok($image->width  <= 80, 'thumbnail width <= 80');
ok($image->height <= 60, 'thumbnail height <= 60');

$mech->back;

$mech->get_ok('http://localhost/', 'new layout works');
$mech->follow_link_ok({ url_regex => qr(folder_1) });

$mech->title_is('Folder 1', 'We got to the first subfolder with page elements');

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 2 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->ok('id("subnav")', 'subnav found');

    $mech->follow_link_ok({ url_regex => qr(folder_2) });
}

