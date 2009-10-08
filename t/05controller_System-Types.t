use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 21 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

$mech->follow_link_ok({url_regex => qr(site/edit)}, 'Edit Site');
$mech->title_is('Edit type Site');
$mech->content_like(qr/value="site"/, 'ID field correct');
$mech->content_like(qr/value="Site"/, 'name field correct');
$mech->content_unlike(qr/checked="checked"/, 'page_element not checked');

$mech->back;

$mech->submit_form_ok({
    with_fields => {
        id           => 'textarea',
        name         => 'Textarea',
        page_element => '1',
    },
    button => 'save',
}, 'Create the textarea type');
$mech->title_is('Edit type Textarea');
$mech->content_like(qr/value="textarea"/, 'ID field correct');
$mech->content_like(qr/value="Textarea"/, 'name field correct');
$mech->content_like(qr/checked="checked"/, 'page_element checked');

$mech->submit_form_ok({
    with_fields => {
        id        => 'text',
        name      => 'Text',
        data_type => 'Text',
        mandatory => 1,
    },
}, 'Create the text attribute');

$mech->content_like(qr!<td>text</td>!, 'new attribute present');
$mech->content_like(qr!<td>Text</td>!, 'new attribute name correct');
$mech->content_like(qr!<td>Text</td>!, 'new attribute type correct');

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

$mech->follow_link_ok({url_regex => qr{/manage\z}}, 'Follow link to content management');
