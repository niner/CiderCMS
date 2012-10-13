use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use File::Slurp;

$model->create_type($c, {id => 'news', name => 'News', page_element => 0});
$model->create_attribute($c, {
    type          => 'news',
    id            => 'title',
    name          => 'Title',
    sort_id       => 0,
    data_type     => 'String',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});
$model->create_type($c, {id => 'appointment', name => 'Appointment', page_element => 0});
$model->create_attribute($c, {
    type          => 'appointment',
    id            => 'title',
    name          => 'Title',
    sort_id       => 0,
    data_type     => 'String',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});

my $news = CiderCMS::Object->new({
    c           => $c,
    type        => 'news',
    parent      => 1,
    parent_attr => 'children',
    level       => 1,
    data        => {
        title => 'testnews',
    },
});
$news->insert;

my $appointment = CiderCMS::Object->new({
    c           => $c,
    type        => 'appointment',
    parent      => 1,
    parent_attr => 'children',
    level       => 1,
    data        => {
        title => 'testappointment',
    },
});
$appointment->insert;

my $site = $model->get_object($c, 1);
my $children = $site->attribute('children');

is(scalar @{ $children->data }, 2, 'two children found');

my @news = $children->objects_by_type('news');
is(scalar @news, 1, 'one news child found');
is($news[0]->{type}, 'news', 'found object is a news');

my @appointments = $children->objects_by_type('appointment');
is(scalar @appointments, 1, 'one appointment child found');
is($appointments[0]->{type}, 'appointment', 'found object is an appointment');

srand(1);
my @random = @{ $children->random };
is($random[0]->{type}, 'news', 'news first');
is($random[1]->{type}, 'appointment', 'appointment second');

srand(2);
@random = @{ $children->random };
is($random[0]->{type}, 'appointment', 'appointment first');
is($random[1]->{type}, 'news', 'news second');

done_testing;
