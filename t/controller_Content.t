use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use FindBin qw($Bin);

$model->create_type($c, {id => 'folder', name => 'Folder', page_element => 0});
$model->create_attribute($c, {
    type          => 'folder',
    id            => 'title',
    name          => 'Title',
    sort_id       => 0,
    data_type     => 'Title',
    repetitive    => 0,
    mandatory     => 1,
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

$model->create_type($c, {id => 'textarea', name => 'Textarea', page_element => 1});
$model->create_attribute($c, {
    type          => 'textarea',
    id            => 'text',
    name          => 'Text',
    sort_id       => 0,
    data_type     => 'Text',
    repetitive    => 0,
    mandatory     => 1,
});

system (
    '/bin/cp', '-r',
    "$Bin/test.example/templates",
    "$Bin/test.example/static",
    "$Bin/../root/instances/$instance/"
);

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Foo bar baz!',
    },
    button => 'save',
});

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Folder 1',
    },
    button => 'save',
});
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=textarea} }, 'Add a textarea');
$mech->submit_form_ok({
    with_fields => {
        text => 'Page 1',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/index.html");

$mech->content_contains('Page 1', 'get_object works');

$mech->title_like(qr/test instance/, 'Title correct');
$mech->content_like(qr/Foo bar baz!/, 'Textarea present');
my $styles = $mech->find_link(url_regex  => qr{styles.css});
$mech->links_ok([ $styles ]);

$mech->get_ok("http://localhost/$instance/folder_1", 'URI without index.html works');
$mech->get_ok("http://localhost/$instance/", 'Root URI without index.html works');

done_testing;
