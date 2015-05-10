use 5.14.0;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use CiderCMS::Test;
my $c = CiderCMS::Test::context;

my $model = $c->model('DB');
my $dbh = $model->dbh;

foreach my $instance (@{ $model->instances }) {
    say $instance;
    $model->txn_do(sub {
        $dbh->do("set search_path=?", undef, $instance);
        my $sys_object = $dbh->quote_identifier(undef, $instance, 'sys_object');
        my $objects = $dbh->selectall_arrayref(
            "select * from $sys_object where parent is not null order by parent, parent_attr, sort_id",
            {Slice => {}},
        );
        my $parent = 0;
        my $parent_attr = '';
        my $sort_id;
        foreach my $object (@$objects) {
            if ($parent != $object->{parent} or $parent_attr ne $object->{parent_attr}) {
                $sort_id     = 0;
                $parent      = $object->{parent};
                $parent_attr = $object->{parent_attr};
                $dbh->do(
                    "update $sys_object set sort_id = -sort_id where parent = ? and parent_attr = ?",
                    undef,
                    $parent,
                    $parent_attr,
                );
            }
            $sort_id++;
            say "$object->{parent}/$object->{parent_attr}: $object->{sort_id} => $sort_id";
            $dbh->do(
                "update $sys_object set sort_id = ? where id = ?",
                undef,
                $sort_id,
                $object->{id},
            );
        }
    });
}
