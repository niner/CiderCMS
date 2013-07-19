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
                id            => 'testtime',
                data_type     => 'Time',
                mandatory     => 1,
            },
        ],
        template => 'time_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        testtime => '08:00',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is(
    '' . $mech->find_xpath('//div[@class="time"]/text()'),
    '08:00:00',
    'time displayed'
);
is(
    '' . $mech->find_xpath('//div[@class="time_hm"]/text()'),
    '08:00',
    'time/format pattern %H:%M works'
);

done_testing;
