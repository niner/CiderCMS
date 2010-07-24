use strict;
use warnings;

use Test::More tests => 3;
use FindBin qw($Bin);
use DBI;

ok(system("rm -Rf $Bin/../root/instances/test.example") == 0);

my $dbh = DBI->connect('dbi:Pg:database=cidercms');

ok($dbh->do(q{set client_min_messages='warning'}));
ok($dbh->do(q{drop schema if exists "test.example" cascade}));
