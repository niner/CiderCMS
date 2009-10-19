use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 45 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/manage' );

# Create a new textarea
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Foo qux baz!',
    },
    button => 'save',
});
$mech->content_like(qr/Foo qux baz!/, 'New textarea present');

# Edit the textarea
$mech->follow_link_ok({ url_regex => qr{2/manage} }, 'Edit textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Foo bar baz!',
    },
    button => 'save',
});
$mech->content_like(qr/Foo bar baz!/, 'New textarea content');

# Add a second textarea and delete it
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a second textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Delete me!',
    }      ,
    button => 'save',
});
$mech->content_like(qr/Delete me!/, 'New textarea content');
$mech->follow_link_ok({ url_regex => qr{manage_delete\b.*\bid=3} }, 'Delete new textarea');
$mech->content_unlike(qr/Delete me!/, 'Textarea gone');

# Try some image
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=image} }, 'Add an image');
$mech->submit_form_ok({
    with_fields => {
        img => "$Bin/../root/static/images/catalyst_logo.png",
    }      ,
    button => 'save',
});
my $image = $mech->find_image(url_regex => qr{catalyst_logo.png});
warn $image->url;
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

# Add a textarea to our folder
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Page 1',
    },
    button => 'save',
});
$mech->title_is('Edit Folder', 'Editing folder again');

$mech->follow_link_ok({ url_regex => qr(test.example/manage) }, 'Back to top level');
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 0',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr(test.example/manage) }, 'Back to top level');
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
$mech->follow_link_ok({ url_regex => qr(test.example/manage) }, 'Back to top level');

$mech->content_like(qr((?s)folder_0.*folder_1.*folder_2), 'Folders in correct order');

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 12 if $@;

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
}
