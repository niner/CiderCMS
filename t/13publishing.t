use strict;
use warnings;
use utf8;

use Test::More;
use FindBin qw($Bin);

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan skip_all => 'Test::WWW::Mechanize::Catalyst required' if $@;

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/manage' );

$mech->submit_form_ok({
    with_fields => {
        publish_uri => "file:///tmp/cidercms-test/",
    },
    button => 'save',
});

$mech->follow_link_ok({ url_regex => qr(/system/publish) }, 'Publish website');

done_testing;
