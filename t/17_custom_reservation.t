use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use File::Slurp;

$model->create_type($c, {id => 'folder', name => 'Folder', page_element => 0});
$model->create_attribute($c, {
    type          => 'folder',
    id            => 'title',
    name          => 'Title',
    sort_id       => 0,
    data_type     => 'Title',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});
$model->create_attribute($c, {
    type          => 'folder',
    id            => 'children',
    name          => 'Children',
    sort_id       => 1,
    data_type     => 'Object',
    repetitive    => 1,
    mandatory     => 0,
});

$model->create_type($c, {id => 'reservation', name => 'Reservation', page_element => 1});
$model->create_attribute($c, {
    type          => 'reservation',
    id            => 'date',
    name          => 'Date',
    sort_id       => 0,
    data_type     => 'Date',
    repetitive    => 0,
    mandatory     => 1,
});
$model->create_attribute($c, {
    type          => 'reservation',
    id            => 'user',
    name          => 'User',
    sort_id       => 0,
    data_type     => 'String',
    repetitive    => 0,
    mandatory     => 0,
});

$model->create_type($c, {id => 'airplane', name => 'Airplane', page_element => 1});
$model->create_attribute($c, {
    type          => 'airplane',
    id            => 'title',
    name          => 'Title',
    sort_id       => 0,
    data_type     => 'Title',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});
$model->create_attribute($c, {
    type          => 'airplane',
    id            => 'reservations',
    name          => 'Reservations',
    sort_id       => 1,
    data_type     => 'Object',
    repetitive    => 1,
    mandatory     => 0,
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a normal folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Airplanes',
    },
    button => 'save'
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
$mech->content_contains('Keine Reservierungen eingetragen.');
my $date = DateTime->now->ymd('-');
$mech->submit_form_ok({
    with_fields => {
        date => $date,
    }
});
$mech->content_lacks('Keine Reservierungen eingetragen.');
$mech->content_contains($date);

done_testing;
