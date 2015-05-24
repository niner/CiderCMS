use strict;
use warnings;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use FindBin qw($Bin);
use utf8;

# add a File type to test File attributes
CiderCMS::Test->populate_types({
    CiderCMS::Test->std_folder_type,
    file => {
        name       => 'File',
        attributes => [
            {
                id            => 'file',
                mandatory     => 1,
            },
            {
                id            => 'title',
                data_type     => 'String',
                mandatory     => 0,
            },
        ],
        page_element => 1,
        template => 'file.zpt'
    },
});

my $root = $model->get_object($c, 1);
    my $folder = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Folder 0' },
    );

$mech->get_ok("http://localhost/$instance/manage");

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

done_testing;
