use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

$mech->get_ok("http://localhost/$instance/manage");

$mech->submit_form_ok({
    with_fields => {
        publish_uri => "file:///tmp/cidercms-test/",
    },
    button => 'save',
});

$mech->follow_link_ok({ url_regex => qr(/system/publish) }, 'Publish website');

done_testing;
