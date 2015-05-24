use strict;
use warnings;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use MIME::Lite;
use utf8;

my $sent_mail;
MIME::Lite->send(sub => sub {
    my ($self) = @_;

    $sent_mail = $self->as_string;
});

# add a Contact type to test Recipient attributes
CiderCMS::Test->populate_types({
    contact => {
        name       => 'Contact form',
        attributes => [
            {
                id            => 'recipient',
                mandatory     => 1,
            },
            {
                id            => 'subject',
                data_type     => 'String',
                mandatory     => 1,
            },
        ],
        page_element => 1,
        template => 'contact.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=contact} }, 'Add a form');
$mech->submit_form_ok({
    with_fields => {
        recipient => 'nine',
        subject   => 'Testform',
    },
    button => 'save',
});

$mech->get_ok("http://localhost/$instance/index.html");

$mech->submit_form_ok({
    with_fields => {
        foo => 'Foo',
        bar => "Bar\nBaz",
    },
    button => 'send',
});

ok($sent_mail =~ /Subject: Testform/, 'Subject of sent mail correct');
ok($sent_mail =~ /To: nine/, 'Recipient of sent mail correct');
like($sent_mail, qr/\n\nbar: Bar\r?\nBaz\nfoo: Foo/s, 'Text of sent mail correct');

done_testing;
