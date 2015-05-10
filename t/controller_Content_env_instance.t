use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Image::Imlib2;

CiderCMS::Test->populate_types({
    CiderCMS::Test->std_folder_type,
    CiderCMS::Test->std_textfield_type,
});

CiderCMS::Test->populate_types({
    image => {
        name         => 'Image',
        page_element => 1,
        attributes   => [
            {
                id            => 'img',
                data_type     => 'Image',
                mandatory     => 1,
            },
        ],
    },
});

system ('/bin/cp', '-r', "$Bin/test.example/templates", "$Bin/test.example/static", "$Bin/../root/instances/$instance/");

my $root = $model->get_object($c, 1);
    $root->create_child(
        attribute => 'children',
        type      => 'textfield',
        data      => {
            text => 'Foo bar baz!',
        },
    );
    my $folder = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Folder 1' },
    );
        my $sub_folder = $folder->create_child(
            attribute => 'children',
            type      => 'folder',
            data      => { title => 'Folder 2' },
        );
            my $sub_sub_folder = $sub_folder->create_child(
                attribute => 'children',
                type      => 'folder',
                data      => { title => 'Folder 3' },
            );
                $sub_sub_folder->create_child(
                    attribute => 'children',
                    type      => 'textfield',
                    data      => {
                        text => 'Foo bar baz!',
                    },
                );

$mech->add_header(cidercms_instance => $instance);

$mech->get_ok('http://localhost/index.html');

$mech->title_is('test instance', 'Title correct');

$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
my $styles = $mech->follow_link_ok({url_regex  => qr{styles.css}});

$mech->get_ok('http://localhost/', 'short URI without index.html works');

# images work
$mech->get_ok("http://localhost/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=image} }, 'Add an image');

$mech->submit_form_ok({
    with_fields => {
        img => "$Bin/../root/static/images/catalyst_logo.png",
    },
    button => 'save',
});

$mech->get_ok('http://localhost/index.html');
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

$mech->title_is('Folder 3', 'We got to the first subfolder with page elements');

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 2 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->ok('id("subnav")', 'subnav found');

    $mech->follow_link_ok({ url_regex => qr(folder_2) });
}

done_testing;
