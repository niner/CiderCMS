use strict;
use warnings;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

is($mech->get("http://localhost/$instance/not_existing")->code, 404, 'test the 404 response');

$mech->get_ok("http://localhost/$instance/manage");

done_testing;
