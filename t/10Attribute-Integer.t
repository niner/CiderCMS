use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 8 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

$mech->follow_link_ok({ url_regex => qr{image/edit} }, 'Edit image type' );
$mech->submit_form_ok({
    with_fields => {
        id        => 'width',
        name      => 'Image width',
        data_type => 'Integer',
    },
}, 'Add width attribute');

$mech->get_ok( 'http://localhost/test.example/manage' );

# Try some image
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=image} }, 'Add an image');
$mech->submit_form_ok({
    with_fields => {
        img   => "$Bin/../root/static/images/catalyst_logo.png",
        width => 100,
    }      ,
    button => 'save',
});
my $image = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($image->url);
$mech->back;
