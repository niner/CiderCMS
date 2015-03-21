use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use FindBin qw($Bin);

CiderCMS::Test->populate_types({
    gallery => {
        name       => 'Gallery',
        attributes => [
            {
                id            => 'title',
                data_type     => 'Title',
                mandatory     => 1,
            },
            {
                id            => 'images',
                data_type     => 'Object',
                mandatory     => 0,
                repetitive    => 1,
            },
        ],
    },
    gallery_image => {
        name         => 'Gallery image',
        page_element => 1,
        attributes   => [
            {
                id            => 'image',
                data_type     => 'Image',
                mandatory     => 1,
            },
        ],
    },
});

system ('/bin/cp', '-r', "$Bin/test.example/import", "$Bin/../root/instances/$instance/");

$mech->get_ok( "http://localhost/$instance/manage" );
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
