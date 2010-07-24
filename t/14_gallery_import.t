use strict;
use warnings;
use utf8;

use Test::More;
use FindBin qw($Bin);

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan skip_all => "Test::WWW::Mechanize::Catalyst required: $@" if $@;

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

# add a gallery type
$mech->submit_form_ok({
    with_fields => {
        id           => 'gallery',
        name         => 'Gallery',
        page_element => 0,
    },
    button => 'save',
}, 'Create gallery type');
$mech->submit_form_ok({
    with_fields => {
        id         => 'title',
        name       => 'Title',
        data_type  => 'Title',
        mandatory  => 1,
    },
}, 'Add images attribute');
$mech->submit_form_ok({
    with_fields => {
        id         => 'images',
        name       => 'Images',
        data_type  => 'Object',
        mandatory  => 0,
        repetitive => 1,
    },
}, 'Add images attribute');

$mech->get_ok( 'http://localhost/test.example/system/types' );

# add a gallery type
$mech->submit_form_ok({
    with_fields => {
        id           => 'gallery_image',
        name         => 'Gallery image',
        page_element => 1,
    },
    button => 'save',
}, 'Create gallery image type');
$mech->submit_form_ok({
    with_fields => {
        id         => 'image',
        name       => 'Image',
        data_type  => 'Image',
        mandatory  => 1,
    },
}, 'Add image attribute');

system ('/bin/cp', '-r', "$Bin/test.example/import", "$Bin/../root/instances/test.example/");

$mech->get_ok( 'http://localhost/test.example/manage' );
$mech->content_lacks('Import images');

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=gallery} }, 'Add a gallery');
$mech->submit_form_ok({
    with_fields => {
        title => 'Gallery',
    },
    button => 'save',
});

$mech->follow_link_ok({ text => 'Import images' }, 'Import is now available');

is(scalar @{ $mech->find_all_links(text => 'Gallery image') }, 2, 'Images imported');

done_testing;
