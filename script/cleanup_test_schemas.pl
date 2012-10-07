use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use CiderCMS;
use File::Path qw(remove_tree);

my $dbh = CiderCMS->new->model('DB')->dbh;
my $schemas = $dbh->selectcol_arrayref("select nspname from pg_catalog.pg_namespace where nspname like 'test%'");

foreach (@$schemas) {
    $dbh->do(qq(drop schema "$_" cascade));
    remove_tree("$Bin/../root/instances/$_");
}
