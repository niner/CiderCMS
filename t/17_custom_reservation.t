use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use File::Slurp;

CiderCMS::Test->populate_types({
    folder => {
        name       => 'Folder',
        attributes => [
            {
                id            => 'title',
                mandatory     => 1,
            },
            {
                id            => 'children',
                data_type     => 'Object',
                repetitive    => 1,
            },
        ],
    },
    user => {
        name         => 'User',
        page_element => 1,
        attributes   => [
            {
                id            => 'username',
                data_type     => 'String',
                mandatory     => 1,
            },
            {
                id            => 'password',
                mandatory     => 1,
            },
            {
                id            => 'name',
                data_type     => 'String',
            },
        ],
    },
    reservation => {
        name         => 'Reservation',
        page_element => 1,
        attributes   => [
            {
                id            => 'date',
                mandatory     => 1,
            },
            {
                id            => 'start',
                data_type     => 'Time',
                mandatory     => 1,
            },
            {
                id            => 'end',
                data_type     => 'Time',
                mandatory     => 1,
            },
            {
                id            => 'user',
                data_type     => 'String',
            },
            {
                id            => 'info',
                data_type     => 'String',
            },
            {
                id            => 'cancelled_by',
                data_type     => 'String',
            },
        ],
    },

    airplane => {
        name         => 'Airplane',
        page_element => 1,
        attributes   => [
            {
                id            => 'title',
                mandatory     => 1,
            },
            {
                id            => 'reservations',
                data_type     => 'Object',
                repetitive    => 1,
            },
            {
                id            => 'reservation_time_limit',
                data_type     => 'Integer',
            },
        ],
        template => 'airplane.zpt'
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a normal folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Users',
    },
    button => 'save'
});
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=user} }, 'Add a user');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        name     => 'test',
        password => 'test',
    },
    button => 'save',
});
$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add the airplane folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Airplanes',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=airplane} }, 'Add an airplane');
$mech->submit_form_ok({
    with_fields => {
        title                  => 'Dimona',
    },
    button => 'save'
});
$mech->get_ok("http://localhost/$instance/airplanes/dimona/index.html");
$mech->content_contains('Keine Reservierungen eingetragen.');
$mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
});
my $date = DateTime->now;
$mech->submit_form_ok({
    with_fields => {
        date  => $date->ymd,
        start => '08:00',
        end   => '11:30',
        info  => 'Testflug',
    },
    button => 'save',
});
$mech->content_lacks('Keine Reservierungen eingetragen.');
ok($mech->find_xpath(qq{//td[text()="Heute"]}), "Today's reservation listed");
ok($mech->find_xpath(qq{//td[text()="test"]}), 'reserving user listed');
ok($mech->find_xpath(qq{//td[text()="Testflug"]}), 'Info listed');

$date->add(days => 1);
$mech->submit_form_ok({
    with_fields => {
        date  => $date->ymd,
        start => '08:00',
        end   => '11:30',
        info  => 'Testflug',
    },
    button => 'save',
});
ok($mech->find_xpath(q{//td[text()="Heute"]}), "Today's reservation still listed");
ok($mech->find_xpath(q{//td[text()="} . $date->ymd . q{"]}), "Tomorrow's reservation listed");

$mech->get_ok(
    $mech->find_xpath(q{//tr[td="Heute"]/td/a[@class="cancel"]/@href}),
    'cancel reservation'
);
is('' . $mech->find_xpath(q{//td[text()="Heute"]}), '', "Today's reservation gone");
ok($mech->find_xpath(q{//td[text()="} . $date->ymd . q{"]}), "Tomorrow's reservation still listed");

$mech->get_ok("http://localhost/$instance/airplanes/dimona/6/manage");
is($mech->value('cancelled_by'), 'test');

# Update to test advance time limit
$mech->get_ok("http://localhost/$instance/airplanes/dimona/manage");
$mech->submit_form_ok({
    with_fields => {
        title                  => 'Dimona',
        reservation_time_limit => 24,
    },
    button => 'save'
});

# test error handling

$mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
$mech->submit_form_ok({
    with_fields => {
        date  => 'invalid',
        start => 'nonsense',
        end   => 'forget',
        info  => '',
    },
    button => 'save',
});
ok($mech->find_xpath('//span[text() = "invalid"]'), 'error message for invalid date found');

my $now = DateTime->now;
$mech->submit_form_ok({
    with_fields => {
        date  => $now->ymd,
        start => $now->hms,
        end   => $now->clone->add(hours => 1)->hms,
        info  => 'too close',
    },
    button => 'save',
});
ok($mech->find_xpath('//span[text() = "too close"]'), 'error message for too close date found');

$now = DateTime->now->add(days => 2)->add(hours => 4);
$mech->submit_form_ok({
    with_fields => {
        date  => $now->ymd,
        start => $now->hms,
        end   => $now->clone->add(hours => 1)->hms,
        info  => 'too close',
    },
    button => 'save',
});
is(
    '' . $mech->find_xpath('//span[text() = "too close"]'),
    '',
    'error message for too close date found'
);

done_testing;
