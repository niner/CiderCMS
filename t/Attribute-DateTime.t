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
                id            => 'test',
                data_type     => 'DateTime',
                mandatory     => 1,
            },
        ],
        template => 'datetime_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        test_date => 'invalid',
        test_time => '25:12',
    },
    button => 'save',
});
ok($mech->find_xpath('//span[text() = "invalid"]'), 'error message for invalid date and time found');

$mech->submit_form_ok({
    with_fields => {
        test_date => 'invalid',
        test_time => '08:00',
    },
    button => 'save',
});
ok($mech->find_xpath('//span[text() = "invalid"]'), 'error message for invalid date found');

my $today = DateTime->today;
$mech->submit_form_ok({
    with_fields => {
        test_date => $today->ymd,
        test_time => 'invalid',
    },
    button => 'save',
});
ok($mech->find_xpath('//span[text() = "invalid"]'), 'error message for invalid time found');

$mech->submit_form_ok({
    with_fields => {
        test_date => $today->ymd,
        test_time => '08:00',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is(
    '' . $mech->find_xpath('//div[@class="datetime"]/text()'),
    $today->ymd . ' 08:00:00',
    'datetime displayed'
);
is('' . $mech->find_xpath('//div[@class="date_today"]/text()'), 'today', 'today recoginzed');
is(
    '' . $mech->find_xpath('//div[@class="time_hm"]/text()'),
    '08:00',
    'time/format pattern %H:%M works'
);

$mech->follow_link_ok({ url_regex => qr{/2/manage} });
$mech->submit_form_ok({
    with_fields => {
        test_date => 'invalid',
    },
    button => 'save',
});
ok(
    $mech->find_xpath('//span[text() = "invalid"]'),
    'error message for invalid date on update found'
);
$mech->submit_form_ok({
    with_fields => {
        test_date => $today->clone->add(days => 1)->ymd,
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is(
    '' . $mech->find_xpath('//div[@class="date_today"]/text()'),
    'another day',
    'tomorrow recognized'
);

done_testing;
