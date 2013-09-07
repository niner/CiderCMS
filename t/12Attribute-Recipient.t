use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use MIME::Lite;
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 13 );

my $sent_mail;
MIME::Lite->send(sub => sub {
    my ($self) = @_;

    $sent_mail = $self->as_string;
});

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

# add a Contact type to test Recipient attributes
$mech->submit_form_ok({
    with_fields => {
        id           => 'contact',
        name         => 'Contact form',
        page_element => 1,
    },
    button => 'save',
}, 'Create Contact form type');
$mech->submit_form_ok({
    with_fields => {
        id        => 'recipient',
        name      => 'Recipient',
        data_type => 'Recipient',
        mandatory => 1,
    },
}, 'Add recipient attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'subject',
        name      => 'Subject',
        data_type => 'String',
        mandatory => 0,
    },
}, 'Add subject attribute');

$mech->get_ok( 'http://localhost/test.example/manage' );

$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=contact} }, 'Add a form');
$mech->submit_form_ok({
    with_fields => {
        recipient => 'nine',
        subject   => 'Testform',
    },
    button => 'save',
});

$mech->get_ok( 'http://localhost/test.example/index.html' );

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
