use strict;
use warnings;
use utf8;

use Test::More;
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use FindBin qw($Bin);
use Regexp::Common qw(URI);

my ($root, $users, $restricted);
setup_test_instance();
test_registration_not_offered();
setup_registration_objects();
test_registration();

done_testing;

sub setup_test_instance {
    setup_types();
    setup_objects();
}

sub setup_types {
    setup_folder_type();
    setup_textarea_type();
    setup_userlist_type();
    setup_user_type();
    setup_registration_type();
}

sub setup_folder_type {
    CiderCMS::Test->populate_types({
        folder => {
            name       => 'Folder',
            template   => 'folder.zpt',
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

sub setup_textarea_type {
    CiderCMS::Test->populate_types({
        textarea => {
            name         => 'Textarea',
            template     => 'textarea.zpt',
            page_element => 1,
            attributes => [
                {
                    id        => 'text',
                    mandatory => 1,
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
    CiderCMS::Test->write_template('user', q(<div
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

sub setup_registration_type {
    CiderCMS::Test->populate_types({
        registration => {
            name       => 'Registration',
            template   => 'registration.zpt',
            attributes => [
                {
                    id        => 'children',
                    data_type => 'Object',
                },
                {
                    id        => 'success',
                    data_type => 'Object',
                },
                {
                    id        => 'verified',
                    data_type => 'Object',
                },
            ],
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
}

sub setup_registration_objects {
    my $registration = $users->create_child(
        attribute => 'registration',
        type      => 'registration',
        data      => {},
    );
        my $success = $registration->create_child(
            attribute => 'success',
            type      => 'folder',
            data      => { title => 'Success' },
        );
            $success->create_child(
                attribute => 'children',
                type      => 'textarea',
                data      => { text => 'Success! Please check your email.' },
            );
        my $verified = $registration->create_child(
            attribute => 'verified',
            type      => 'folder',
            data      => { title => 'Verified' },
        );
            $verified->create_child(
                attribute => 'children',
                type      => 'textarea',
                data      => { text => 'Success! You are now registered.' },
            );
}

sub test_registration_not_offered {
    $mech->get_ok("http://localhost/$instance/restricted/index.html");
    $mech->content_contains('Login');
    $mech->content_lacks('Neuen Benutzer registrieren');
}

sub test_registration {
    start_registration();
    test_validation();
    test_success();
    test_duplicate();
}

sub start_registration {
    $mech->get_ok("http://localhost/$instance/restricted/index.html");
    $mech->content_contains('Login');
    $mech->content_contains('Neuen Benutzer registrieren');
    $mech->follow_link_ok({text => 'Neuen Benutzer registrieren'});
}

sub test_validation {
    $mech->submit_form_ok({
        with_fields => {
            username => 'testname',
            password => 'testpass',
        },
    });
    $mech->content_contains('missing');
    $mech->submit_form_ok({
        with_fields => {
            password => 'testpass',
            email    => 'test@not-allowed.example',
        },
    });
    $mech->content_contains('invalid');
    $mech->submit_form_ok({
        with_fields => {
            password => 'testpass',
            email    => 'test@localhost',
        },
    });
    $mech->content_contains('Success! Please check your email.');
}

sub test_success {
    my @deliveries = Email::Sender::Simple->default_transport->deliveries;
    is(scalar @deliveries, 1, 'Confirmation message sent');
    my $envelope = $deliveries[0]->{envelope};
    is_deeply($envelope->{to}, ['test@localhost'], 'Confirmation message recipient correct');
    is($envelope->{from}, "noreply\@$instance", 'Confirmation message sender correct');
    my $email = $deliveries[0]->{email};
    is(
        $email->get_header("Subject"),
        "Bestätigung der Anmeldung zu $instance",
        'Confirmation message subject correct'
    );

    my ($link) = $email->get_body =~ /($RE{URI}{HTTP})/;
    $mech->get_ok($link);
    $mech->content_lacks('Login');
    $mech->content_contains('Success! You are now registered.');

    $mech->get_ok("http://localhost/$instance/restricted/index.html");
    $mech->content_contains('Login');
    $mech->submit_form_ok({
        with_fields => {
            username => 'testname',
            password => 'testpass',
        },
    });
    $mech->content_lacks('Login');
    $mech->content_lacks('Invalid username/password');
    $mech->title_is('Restricted');
}

sub test_duplicate {
    $mech->get_ok("http://localhost/system/logout");
    start_registration();
    $mech->submit_form_ok({
        with_fields => {
            username => 'testname',
            password => 'testpass',
            email    => 'test@localhost',
        },
    });
    $mech->content_contains('bereits vergeben', 'duplicate registered found');

    $mech->submit_form_ok({
        with_fields => {
            username => 'testname2',
            password => 'testpass',
            email    => 'test@localhost',
        },
    });
    $mech->content_contains('Success! Please check your email.');

    start_registration();
    $mech->submit_form_ok({
        with_fields => {
            username => 'testname2',
            password => 'testpass',
            email    => 'test@localhost',
        },
    });
    $mech->content_contains('bereits vergeben', 'duplicate unverified found');
}
