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
                id            => 'testdate',
                data_type     => 'Date',
                mandatory     => 1,
            },
        ],
        template => 'date_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        testdate => '2013-07-03',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is('' . $mech->find_xpath('//div[@class="date"]/text()'), '2013-07-03', 'date displayed');

done_testing;

