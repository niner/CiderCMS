use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 17 );

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
        data_type => 'string',
        mandatory => 1,
    },
}, 'Create the text attribute');

$mech->content_like(qr!<td>text</td>!, 'new attribute present');
$mech->content_like(qr!<td>Text</td>!, 'new attribute name correct');
$mech->content_like(qr!<td>string</td>!, 'new attribute type correct');

$mech->follow_link_ok({url_regex => qr{/manage\z}}, 'Follow link to content management');
