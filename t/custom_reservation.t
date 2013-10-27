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
                id            => 'start',
                data_type     => 'DateTime',
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

my $root = $model->get_object($c, 1);
    my $users = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Users' },
    );
        $users->create_child(
            attribute => 'children',
            type      => 'user',
            data      => {
                username => 'test',
                name     => 'test',
                password => 'test',
            },
        );
    my $airplanes = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Airplanes' },
    );
        my $dimona = $airplanes->create_child(
            attribute => 'children',
            type      => 'airplane',
            data      => {
                title => 'Dimona',
            },
        );

$model->txn_do(sub {
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
            start_date => $date->ymd,
            start_time => $date->clone->add(hours => 1)->hour . ':00',
            end        => $date->clone->add(hours => 2)->hour . ':30',
            info       => 'Testflug',
        },
        button => 'save',
    });
    $mech->content_lacks('Keine Reservierungen eingetragen.');
    ok($mech->find_xpath(qq{//td[span="Heute"]}), "Today's reservation listed");
    ok($mech->find_xpath(qq{//td[text()="test"]}), 'reserving user listed');
    ok($mech->find_xpath(qq{//td[text()="Testflug"]}), 'Info listed');

    $date->add(days => 1);
    $mech->submit_form_ok({
        with_fields => {
            start_date => $date->ymd,
            start_time => $date->clone->add(hours => 1)->hour . ':00',
            end        => $date->clone->add(hours => 2)->hour . ':30',
            info       => 'Testflug',
        },
        button => 'save',
    });
    ok($mech->find_xpath(q{//td[span="Heute"]}), "Today's reservation still listed");
    ok($mech->find_xpath(q{//td[span="} . $date->ymd . q{"]}), "Tomorrow's reservation listed");

    $mech->get_ok(
        $mech->find_xpath(q{//tr[td="Heute"]/td/a[@class="cancel"]/@href}),
        'cancel reservation'
    );
    is('' . $mech->find_xpath(q{//td[text()="Heute"]}), '', "Today's reservation gone");
    ok($mech->find_xpath(q{//td[span="} . $date->ymd . q{"]}), "Tomorrow's reservation still listed");

    $mech->get_ok("http://localhost/$instance/airplanes/dimona/6/manage");
    is($mech->value('cancelled_by'), 'test');

    $mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
    $mech->submit_form_ok({
        with_fields => {
            start_date => $date->ymd,
            start_time => $date->clone->add(hours => 2)->hour . ':00',
            end        => $date->clone->add(hours => 3)->hour . ':30',
            info       => 'Testflug2',
        },
        button => 'save',
    });
    ok(
        $mech->find_xpath('//span[text() = "conflicting existent reservation"]'),
        'error message for conflict with existent reservation found'
    );

    $mech->get_ok(
        $mech->find_xpath(q{//tr/td/a[@class="cancel"]/@href}),
        'cancel reservation'
    );
    $mech->submit_form_ok({
        with_fields => {
            start_date => $date->ymd,
            start_time => $date->clone->add(hours => 2)->hour . ':00',
            end        => $date->clone->add(hours => 3)->hour . ':30',
            info       => 'Testflug2',
        },
        button => 'save',
    });
    ok(
        not($mech->find_xpath('//span[text() = "conflicting existent reservation"]')),
        'error message for conflict with existent reservation not found anymore'
    );

    $model->dbh->rollback;
});

$model->txn_do(sub {
    # test error handling

    $mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
    $mech->submit_form_ok({
        with_fields => {
            start_date => 'invalid',
            start_time => 'nonsense',
            end        => 'forget',
            info       => '',
        },
        button => 'save',
    });
    ok($mech->find_xpath('//span[text() = "invalid"]'), 'error message for invalid date found');

    $model->dbh->rollback;
});

$model->txn_do(sub {
    # Update to test advance time limit
    $dimona->set_property(reservation_time_limit => 24);
    $dimona->update;

    my $now = DateTime->now;
    $mech->submit_form_ok({
        with_fields => {
            start_date => $now->ymd,
            start_time => $now->clone->add(hours => 1)->hms,
            end        => $now->clone->add(hours => 2)->hms,
            info       => 'too close',
        },
        button => 'save',
    });
    ok($mech->find_xpath('//span[text() = "too close"]'), 'error message for too close date found');

    $now = DateTime->now->add(days => 2)->add(hours => 4);
    $mech->submit_form_ok({
        with_fields => {
            start_date => $now->ymd,
            start_time => $now->hms,
            end        => $now->clone->add(hours => 1)->hms,
            info       => 'too close',
        },
        button => 'save',
    });
    is(
        '' . $mech->find_xpath('//span[text() = "too close"]'),
        '',
        'error message for too close date gone'
    );

    $model->dbh->rollback;
});

$model->txn_do(sub {
    $mech->get_ok("http://localhost/$instance/airplanes/dimona/index.html");

    ok($mech->find_xpath(qq{//p[text()="Frei"]}), "No reservation active for now");

    $mech->get_ok("http://localhost/$instance/airplanes/dimona/reserve");
    my $date = DateTime->now;
    $mech->submit_form_ok({
        with_fields => {
            start_date => $date->ymd,
            start_time => $date->clone->subtract(hours => 1)->hms(':'),
            end        => $date->clone->add(hours => 2)->hour . ':00',
            info       => 'Testflug',
        },
        button => 'save',
    });

    is('' . $mech->find_xpath(qq{//p[text()="Frei"]}), '', "Reservation active for now");

    $model->dbh->rollback;
});

done_testing;
