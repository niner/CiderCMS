use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 40 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

# check basic form setup
$mech->follow_link_ok({url_regex => qr(site/edit)}, 'Edit Site');
$mech->title_is('Edit type Site');

$mech->form_number(1);
ok($mech->value('id')   eq 'site', 'ID field correct');
ok($mech->value('name') eq 'Site', 'name field correct');
ok((not $mech->value('page_element')), 'page_element not checked');

$mech->back;

# add a textfield type
$mech->submit_form_ok({
    with_fields => {
        id           => 'textfield',
        name         => 'Textfield',
        page_element => '1',
    },
    button => 'save',
}, 'Create the textfield type');
$mech->title_is('Edit type Textfield');
$mech->form_number(1);
ok($mech->value('id')   eq 'textfield', 'ID field correct');
ok($mech->value('name') eq 'Textfield', 'name field correct');
ok($mech->value('page_element'), 'page_element checked');

ok(-e "$Bin/../root/instances/test.example/templates/types/textfield.zpt", 'template got created');

# add the text attribute
$mech->submit_form_ok({
    with_fields => {
        id        => 'text',
        name      => 'Text',
        data_type => 'Text',
        mandatory => 1,
    },
}, 'Create the text attribute');

$mech->form_number(2);
ok($mech->value('text_id')        eq 'text', 'new attribute present');
ok($mech->value('text_name')      eq 'Text', 'new attribute name correct');
ok($mech->value('text_data_type') eq 'Text', 'new attribute type correct');

# rename the type to textarea in two steps to test the fields independently
$mech->submit_form_ok({
    with_fields => {
        id           => 'textfield',
        name         => 'Textarea',
        page_element => 1,
    },
    button => 'save',
}, 'Rename textfield to textarea');
$mech->submit_form_ok({
    with_fields => {
        id           => 'textarea',
        name         => 'Textarea',
        page_element => 1,
    },
    button => 'save',
}, 'Rename textfield to textarea');

# accessing the old name throws an expected error
ok($mech->get('http://localhost/test.example/system/types/textfield/edit')->is_error, 'Old type name gone');
$mech->back;

$mech->follow_link_ok({url_regex => qr(/types$)}, 'Back to types');

# add a folder type with title (String) and children attributes
$mech->submit_form_ok({
    with_fields => {
        id   => 'folder',
        name => 'Folder',
    },
    button => 'save',
}, 'Create folder type');
$mech->submit_form_ok({
    with_fields => {
        id        => 'title',
        name      => 'Title',
        data_type => 'String',
        mandatory => 1,
    },
}, 'Add title attribute');
$mech->submit_form_ok({
    with_fields => {
        id         => 'children',
        name       => 'Children',
        data_type  => 'Object',
        repetitive => 1,
    },
}, 'Add title attribute');

# now change the title's type to Title
$mech->submit_form_ok({
    with_fields => {
        title_sort_id    => 1,
        children_sort_id => 2,
        title_data_type  => 'Title',
    },
    button => 'save',
});

$mech->form_number(2);
is($mech->value('title_data_type'), 'Title', 'title data_type now Title');
is($mech->value('title_sort_id'), 1, 'title sort_id correct');
is($mech->value('children_sort_id'), 2, 'children sort_id correct');
$mech->content_like(qr/title_sort_id.*children_sort_id/xms, 'Attributes in correct order');

$mech->follow_link_ok({url_regex => qr(/types$)}, 'Back to types');

# add an image type to test Image attributes
$mech->submit_form_ok({
    with_fields => {
        id           => 'image',
        name         => 'Image',
        page_element => 1,
    },
    button => 'save',
}, 'Create image type');
$mech->submit_form_ok({
    with_fields => {
        id        => 'img',
        name      => 'Image file',
        data_type => 'Image',
        mandatory => 1,
    },
}, 'Add image file attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'title',
        name      => 'Title',
        data_type => 'String',
        mandatory => 0,
    },
}, 'Add title attribute');

$mech->follow_link_ok({url_regex => qr(/types$)}, 'Back to types');

# add a news type to test Date attributes

$mech->submit_form_ok({
    with_fields => {
        id           => 'news',
        name         => 'News',
        page_element => 1,
    },
    button => 'save',
}, 'Create news type');
$mech->submit_form_ok({
    with_fields => {
        id        => 'date',
        name      => 'Date',
        data_type => 'Date',
        mandatory => 1,
    },
}, 'Add date attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'title',
        name      => 'Title',
        data_type => 'String',
        mandatory => 1,
    },
}, 'Add title attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'text',
        name      => 'Text',
        data_type => 'Text',
        mandatory => 0,
    },
}, 'Create the text attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'image',
        name      => 'Image',
        data_type => 'Image',
        mandatory => 0,
    },
}, 'Add image file attribute');

# beef up our layout
system ('/bin/cp', '-r', "$Bin/test.example/templates", "$Bin/test.example/static", "$Bin/../root/instances/test.example/");

$mech->follow_link_ok({url_regex => qr{/manage\z}}, 'Follow link to content management');
