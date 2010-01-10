use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 6 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/manage' );

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add the News folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'News',
    },
    button => 'save',
});

# Add some news to our folder
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=news} }, 'Add a news post');
$mech->submit_form_ok({
    with_fields => {
        date  => '2009-11-01',
        title => 'Test news!',
        text  => 'Test text for the test news',
    },
    button => 'save',
});
