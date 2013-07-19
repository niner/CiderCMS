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
        ]
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
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a normal folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Airplanes',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=airplane} }, 'Add an airplane');
$mech->submit_form_ok({
    with_fields => {
        title => 'Dimona',
    },
    button => 'save'
});
$mech->get_ok("http://localhost/$instance/airplanes/dimona/index.html");
$mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
});
$mech->content_contains('Keine Reservierungen eingetragen.');
my $date = DateTime->now->ymd('-');
$mech->submit_form_ok({
    with_fields => {
        date  => $date,
        start => '08:00',
        end   => '11:30',
        info  => 'Testflug',
    }
});
$mech->content_lacks('Keine Reservierungen eingetragen.');
ok($mech->find_xpath(qq{//td[text()="$date"]}), 'reserved date listed');
ok($mech->find_xpath(qq{//td[text()="test"]}), 'reserving user listed');
ok($mech->find_xpath(qq{//td[text()="Testflug"]}), 'Info listed');

done_testing;
