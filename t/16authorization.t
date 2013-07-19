use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use File::Slurp;
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
$model->create_attribute($c, {
    type          => 'folder',
    id            => 'children',
    name          => 'Children',
    sort_id       => 1,
    data_type     => 'Object',
    repetitive    => 0,
    mandatory     => 0,
    default_value => 0,
});

$model->create_type($c, {id => 'user', name => 'User', page_element => 1});
$model->create_attribute($c, {
    type          => 'user',
    id            => 'username',
    name          => 'Name',
    sort_id       => 0,
    data_type     => 'String',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});
$model->create_attribute($c, {
    type          => 'user',
    id            => 'password',
    name          => 'Password',
    sort_id       => 1,
    data_type     => 'Password',
    repetitive    => 0,
    mandatory     => 1,
    default_value => '',
});
open my $template, '>', "$Bin/../root/instances/$instance/templates/types/user.zpt";
print $template q(<div
    xmlns:tal="http://purl.org/petal/1.0/"
    tal:attributes="id string:object_${self/id}"
    tal:content="self/property --username"
/>);
close $template;

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=folder} }, 'Add a folder');
$mech->submit_form_ok({
    with_fields => {
        title => 'Users',
    },
    button => 'save',
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

$mech->get_ok("http://localhost/$instance/users/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=user} }, 'Add a user');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
    button => 'save',
});

ok($mech->find_xpath('//div[text()="test"]'), 'new user listed');

# Try logging in with the wrong password
$mech->get_ok("http://localhost/$instance/restricted/index.html");
$mech->content_contains('Login');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'wrong',
    },
});
$mech->content_contains('Invalid username/password');

# Now that the user exists, try to login again with correct credentials
$mech->get_ok("http://localhost/$instance/restricted/index.html");
$mech->content_contains('Login');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test',
    },
});
$mech->content_lacks('Invalid username/password');
ok($mech->find_xpath('id("object_4")'), 'Login successful');

$mech->get_ok("http://localhost/$instance/users/manage");
$mech->follow_link_ok({text => 'User'});
$mech->submit_form_ok({
    with_fields => {
        password => 'test2',
    },
    button => 'save',
});
$mech->cookie_jar({}); # Logout

$mech->get_ok("http://localhost/$instance/restricted/index.html");
$mech->content_contains('Login');
$mech->submit_form_ok({
    with_fields => {
        username => 'test',
        password => 'test2',
    },
});
$mech->content_lacks('Invalid username/password');
ok($mech->find_xpath('id("object_4")'), 'Login successful');

done_testing;
