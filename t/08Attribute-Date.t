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

my $today = DateTime->today;
$mech->submit_form_ok({
    with_fields => {
        testdate => $today->ymd,
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is('' . $mech->find_xpath('//div[@class="date"]/text()'), $today->ymd, 'date displayed');
is('' . $mech->find_xpath('//div[@class="date_today"]/text()'), 'today', 'today recoginzed');

$mech->follow_link_ok({ url_regex => qr{/2/manage} });
$mech->submit_form_ok({
    with_fields => {
        testdate => $today->clone->add(days => 1)->ymd,
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/manage");

is(
    '' . $mech->find_xpath('//div[@class="date_today"]/text()'),
    'another day',
    'tomorrow recoginzed'
);

done_testing;
