use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

CiderCMS::Test->populate_types({
    tester => {
        name       => 'Tester',
        attributes => [
            {
                id            => 'email',
                mandatory     => 1,
            },
        ],
        page_element => 1,
        template => 'email_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        email => "",
    },
    button => 'save',
});

$mech->content_contains('missing');

$mech->submit_form_ok({
    with_fields => {
        email => "FooBar",
    },
    button => 'save',
});

$mech->content_contains('invalid');

$mech->submit_form_ok({
    with_fields => {
        email => "FooBar@",
    },
    button => 'save',
});

$mech->content_contains('invalid');

$mech->submit_form_ok({
    with_fields => {
        email => 'test@localhost',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/index.html");
is('' . $mech->find_xpath('//div'), 'test@localhost', 'Email saved');

done_testing;
