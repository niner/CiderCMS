use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);

CiderCMS::Test->populate_types({
    CiderCMS::Test->std_folder_type,
    CiderCMS::Test->std_textfield_type,
    image => {
        name         => 'Image',
        page_element => 1,
        attributes   => [
            {
                id            => 'img',
                name          => 'Image file',
                data_type     => 'Image',
                mandatory     => 1,
            },
            {
                id            => 'title',
                name          => 'Title',
                data_type     => 'String',
                mandatory     => 0,
            },
        ],
        template => 'image.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");

# Create a new textfield
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textfield} }, 'Add a textfield');
$mech->submit_form_ok({
    with_fields => {
        text => 'Foo qux baz!',
    },
    button => 'save',
});
$mech->content_like(qr/Foo qux baz!/, 'New textfield present');

# Edit the textfield
$mech->follow_link_ok({ url_regex => qr{2/manage} }, 'Edit textfield');
$mech->submit_form_ok({
    with_fields => {
        text => 'Foo bar baz!',
    },
    button => 'save',
});
$mech->content_like(qr/Foo bar baz!/, 'New textfield content');

# Add a second textfield and delete it
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textfield} }, 'Add a second textfield');
$mech->submit_form_ok({
    with_fields => {
        text => 'Delete me!',
    }      ,
    button => 'save',
});
$mech->content_like(qr/Delete me!/, 'New textfield content');
$mech->follow_link_ok({ url_regex => qr{manage_delete\b.*\bid=3} }, 'Delete new textfield');
$mech->content_unlike(qr/Delete me!/, 'Textarea gone');

# Try some image
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=image} }, 'Add an image');
$mech->submit_form_ok({
    with_fields => {
        img => "$Bin/../root/static/images/catalyst_logo.png",
    }      ,
    button => 'save',
});
my $image = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($image->url);
$mech->back;

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 1',
    },
    button => 'save',
});
$mech->title_is('Edit Folder', 'Editing folder');
ok($mech->uri->path =~ m!/folder_1/!, 'dcid set correctly');

# Add a textfield to our folder
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textfield} }, 'Add a textfield');
$mech->submit_form_ok({
    with_fields => {
        text => 'Page 1',
    },
    button => 'save',
});
$mech->title_is('Edit Folder', 'Editing folder again');

$mech->follow_link_ok({ url_regex => qr($instance/manage) }, 'Back to top level');
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 0',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 0.1',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr($instance/manage) }, 'Back to top level');
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder}, n => 3 }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Földer 2', # try some umlaut
    },
    button => 'save',
});
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 2', # correct it
    },
    button => 'save',
});
ok($mech->value('title') eq 'Folder 2', 'Title updated');
$mech->follow_link_ok({ url_regex => qr($instance/manage) }, 'Back to top level');

$mech->content_like(qr((?s)folder_0.*folder_1.*folder_2), 'Folders in correct order');

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 14 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->like('//div[@class="child folder"][3]/@id', qr/\A child_(\d+) \z/x);
    my $xpc = $xpath->xpc;
    my $child_id = $xpc->findvalue('//div[@class="child folder"][3]/@id');

    $mech->follow_link_ok({ url_regex => qr(folder_1/manage) }, 'Go to folder 1');

    $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpath->ok('id("breadcrumbs")', 'Bread crumbs found');
    $xpath->ok('id("breadcrumbs")//a', 'Links in bread crumbs');
    $xpath->ok('id("breadcrumbs")//a[contains(text(), "Folder")]', 'Folder 1 title in breadcrumbs');
    $xpath->ok('id("breadcrumbs")//a[contains(@href, "folder_1")]', 'Folder 1 href in breadcrumbs');

    $mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a subfolder');
    $mech->submit_form_ok({
        with_fields => {
            title => 'Folder 3',
        },
        button => 'save',
    });

    $mech->follow_link_ok({ url_regex => qr(folder_1/manage) }, 'Back to folder_1');
    $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpc = $xpath->xpc;
    my $folder_3_id = $xpc->findvalue('//div[@class="child folder"][1]/@id');

    my ($id) = $child_id =~ /child_(\d+)/;
    ($folder_3_id) = $folder_3_id =~ /child_(\d+)/;
    $mech->get_ok($mech->uri . "_paste?attribute=children;id=$id;after=$folder_3_id");
    $mech->content_like(qr((?s)folder_3.*folder_2), 'Folders in correct order');
    $mech->follow_link_ok({ url_regex => qr{folder_2/manage} }, 'Folder 2 works');
    $mech->back;

    # now move the textfield to folder_3 to set up for the content tests
    $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    $xpc = $xpath->xpc;
    my $textfield_id = $xpc->findvalue('//div[@class="child textfield"][1]/@id');
    ($textfield_id) = $textfield_id =~ /child_(\d+)/;
    $mech->follow_link_ok({ url_regex => qr{folder_3/manage} });
    $mech->get_ok($mech->uri . "_paste?attribute=children;id=$textfield_id");
}

done_testing;
