use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'CiderCMS' }
BEGIN { use_ok 'CiderCMS::Controller::Content::Management' }

ok( request('/test.example/manage')->is_success, 'Request should succeed' );


