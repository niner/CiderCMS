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
    id            => 'restricted',
    name          => 'Restricted',
    sort_id       => 1,
    data_type     => 'Boolean',
    repetitive    => 0,
    mandatory     => 0,
    default_value => 0,
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Unrestricted',
    },
    button => 'save',
});
$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a restricted folder');
$mech->submit_form_ok({
    with_fields => {
        title      => 'Restricted',
        restricted => '1',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/unrestricted/index.html");
$mech->content_lacks('Login');

# Try accessing restricted content
$mech->get_ok("http://localhost/$instance/restricted/index.html");
$mech->content_contains('Login');
# Try logging in with a non-existing user
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
});
$mech->content_contains('Invalid username/password');

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({url_regex => qr!/authorization!});
$mech->submit_form_ok({
    with_fields => {
        name     => 'test',
        password => 'test',
    },
    button => 'save',
});

ok($mech->find_xpath('//td[a="test"]'), 'new user listed');

# Now that the user exists, try to login again
$mech->get_ok("http://localhost/$instance/restricted/index.html");
$mech->content_contains('Login');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
});
ok($mech->find_xpath('id("object_3")'));

done_testing;
