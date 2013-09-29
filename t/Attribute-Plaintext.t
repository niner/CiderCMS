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
                id            => 'code',
                data_type     => 'Plaintext',
                mandatory     => 0,
            },
        ],
        page_element => 1,
        template => 'plaintext_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        code => "Foo\n    Bar",
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/index.html");
is('' . $mech->find_xpath('//code'), "Foo Bar", 'code displayed with white space');

done_testing;
