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
                id            => 'number',
                data_type     => 'Integer',
                mandatory     => 1,
            },
        ],
        page_element => 1,
        template => 'integer_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        number => '',
    },
    button => 'save',
});

$mech->content_contains('missing');

$mech->submit_form_ok({
    with_fields => {
        number => 'FooBar',
    },
    button => 'save',
});

$mech->content_contains('invalid');

$mech->submit_form_ok({
    with_fields => {
        number => '0 or 1',
    },
    button => 'save',
});

$mech->content_contains('invalid');

$mech->submit_form_ok({
    with_fields => {
        number => '0',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/index.html");
is('' . $mech->find_xpath('//div'), '0', 'Integer saved');

done_testing;
