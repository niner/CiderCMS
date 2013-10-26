use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use File::Slurp qw(write_file);
use FindBin qw($Bin);

my ($root, $users, $restricted);
setup_test_instance();
test_registration_not_offered();
setup_registration();
test_registration();

done_testing;

sub setup_test_instance {
    setup_types();
    setup_objects();
}

sub setup_types {
    setup_folder_type();
    setup_userlist_type();
    setup_user_type();
}

sub setup_folder_type {
    CiderCMS::Test->populate_types({
        folder => {
            name       => 'Folder',
            attributes => [
                {
                    id        => 'title',
                    mandatory => 1,
                },
                {
                    id            => 'restricted',
                    data_type     => 'Boolean',
                    default_value => 0,
                },
                {
                    id            => 'children',
                    data_type     => 'Object',
                },
            ],
        },
    });
}

sub setup_userlist_type {
    CiderCMS::Test->populate_types({
        userlist => {
            name       => 'User list',
            attributes => [{
                    type          => 'userlist',
                    id            => 'title',
                    mandatory     => 1,
                },
                {
                    id            => 'children',
                    data_type     => 'Object',
                },
            ],
        },
    });
}

sub setup_user_type {
    CiderCMS::Test->populate_types({
        user => {
            name         => 'User',
            page_element => 1,
            attributes => [
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
                    id            => 'email',
                    data_type     => 'String',
                    mandatory     => 1,
                },
            ],
        },
    });
    write_file("$Bin/../root/instances/$instance/templates/types/user.zpt", q(<div
        xmlns:tal="http://purl.org/petal/1.0/"
        tal:attributes="id string:object_${self/id}"
        tal:content="self/property --username"
    />));
}

sub setup_objects {
    $root = $model->get_object($c, 1);
        $users = $root->create_child(
            attribute => 'children',
            type      => 'userlist',
            data      => { title => 'Users' },
        );
        $restricted = $root->create_child(
            attribute => 'children',
            type      => 'folder',
            data      => { title => 'Restricted', restricted => 1 },
        );
}

sub setup_registration {
    CiderCMS::Test->populate_types({
        registration => {
            name         => 'Registration',
        },
    });
    $model->create_attribute($c, {
        type          => 'userlist',
        id            => 'registration',
        name          => 'Registration',
        sort_id       => 0,
        data_type     => 'Object',
        repetitive    => 0,
        mandatory     => 0,
        default_value => '',
    });

    $users->create_child(
        attribute => 'registration',
        type      => 'registration',
        data      => {},
    );
}

# Try accessing restricted content
sub test_registration_not_offered {
    $mech->get_ok("http://localhost/$instance/restricted/index.html");
    $mech->content_contains('Login');
    $mech->content_lacks('Neuen Benutzer registrieren');
}

sub test_registration {
    $mech->get_ok("http://localhost/$instance/restricted/index.html");
    $mech->content_contains('Login');
    $mech->content_contains('Neuen Benutzer registrieren');
}
