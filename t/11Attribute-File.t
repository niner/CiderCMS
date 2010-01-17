use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use utf8;

eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 12 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/test.example/system/types' );

# add a File type to test File attributes
$mech->submit_form_ok({
    with_fields => {
        id           => 'file',
        name         => 'File',
        page_element => 1,
    },
    button => 'save',
}, 'Create File type');
$mech->submit_form_ok({
    with_fields => {
        id        => 'file',
        name      => 'File',
        data_type => 'File',
        mandatory => 1,
    },
}, 'Add file attribute');
$mech->submit_form_ok({
    with_fields => {
        id        => 'title',
        name      => 'Title',
        data_type => 'String',
        mandatory => 0,
    },
}, 'Add title attribute');

$mech->get_ok( 'http://localhost/test.example/manage' );

# Try some file
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=file} }, 'Add a file');
$mech->submit_form_ok({
    with_fields => {
        file   => "$Bin/../root/static/images/catalyst_logo.png",
        title  => 'Testfile',
    }      ,
    button => 'save',
});

$mech->follow_link_ok({ text => 'Testfile' });

$mech->back;

SKIP: {
    eval { require Test::XPath; };
    skip 'Test::XPath not installed', 3 if $@;

    my $xpath = Test::XPath->new( xml => $mech->content, is_html => 1 );
    my $xpc = $xpath->xpc;
    my $file_id = $xpc->findvalue('//div[@class="child file"][1]/@id');
    ($file_id) = $file_id =~ /child_(\d+)/;

    $mech->follow_link_ok({ url_regex => qr{folder_0/manage} });
    $mech->get_ok($mech->uri . "_paste?attribute=children;id=$file_id");

    $mech->follow_link_ok({ text => 'Testfile' });
}
