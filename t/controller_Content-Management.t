use strict;
use warnings;
use Test::More;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 8 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/manage' );

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a textarea');

$mech->submit_form_ok({
    with_fields => {
        text => 'Foo qux baz!',
    },
    button => 'save',
});

$mech->content_like(qr/Foo qux baz!/, 'New textarea present');

$mech->follow_link_ok({ url_regex => qr{2/manage} }, 'Edit textarea');

$mech->submit_form_ok({
    with_fields => {
        text => 'Foo bar baz!',
    },
    button => 'save',
});

$mech->content_like(qr/Foo bar baz!/, 'New textarea content');
