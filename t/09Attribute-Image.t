use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 5 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/news/manage' );

# Add some news to our folder
$mech->follow_link_ok({ text => 'edit' }, 'Edit news post');
$mech->submit_form_ok({
    with_fields => {
        image => "$Bin/../root/static/images/catalyst_logo.png",
    },
    button => 'save',
});

my $image = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($image->url);
