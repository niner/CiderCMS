use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 30 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

$mech->follow_link_ok({url_regex => qr(site/edit)}, 'Edit Site');
$mech->title_is('Edit type Site');

$mech->form_number(1);
ok($mech->value('id')   eq 'site', 'ID field correct');
ok($mech->value('name') eq 'Site', 'name field correct');
ok((not $mech->value('page_element')), 'page_element not checked');

$mech->back;

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

ok($mech->get('http://localhost/test.example/system/types/textfield/edit')->is_error, 'Old type name gone');
$mech->back;

$mech->follow_link_ok({url_regex => qr(/types$)}, 'Back to types');

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

$mech->submit_form_ok({
    with_fields => {
        title_data_type => 'Title',
    },
    button => 'save',
});

$mech->form_number(2);
ok($mech->value('title_data_type') eq 'Title', 'title data_type now Title');

$mech->follow_link_ok({url_regex => qr(/types$)}, 'Back to types');

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

$mech->follow_link_ok({url_regex => qr{/manage\z}}, 'Follow link to content management');
