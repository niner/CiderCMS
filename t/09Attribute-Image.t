use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;
use FindBin qw($Bin);

CiderCMS::Test->populate_types({
    tester => {
        name       => 'Tester',
        attributes => [
            {
                id            => 'testimage',
                data_type     => 'Image',
                mandatory     => 1,
            },
        ],
        template => 'image_test.zpt',
    },
});

$mech->get_ok("http://localhost/$instance/manage");
$mech->follow_link_ok({ url_regex => qr{manage_add\b.*\btype=tester} }, 'Add a tester');

$mech->submit_form_ok({
    with_fields => {
        testimage => "$Bin/../root/static/images/catalyst_logo.png",
    },
    button => 'save',
});

my $image = $mech->find_image(url_regex => qr{catalyst_logo});
$mech->get_ok($image->url);

done_testing;
