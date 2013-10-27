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
$model->create_attribute($c, {
    type          => 'news',
    id            => 'show',
    name          => 'Show',
    sort_id       => 1,
    data_type     => 'Boolean',
    repetitive    => 0,
    mandatory     => 1,
    default_value => 1,
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=news} }, 'Add a news post');
is($mech->value('show'), '1', 'default to yes');

done_testing;
