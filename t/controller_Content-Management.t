use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 13 );

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
    },
    button => 'save',
});
$mech->content_like(qr/Delete me!/, 'New textarea content');
$mech->follow_link_ok({ url_regex => qr{manage_delete\b.*\bid=3} }, 'Delete new textarea');
$mech->content_unlike(qr/Delete me!/, 'Textarea gone');
