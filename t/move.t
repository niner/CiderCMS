use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

CiderCMS::Test->populate_types({
    folder => {
        name       => 'Folder',
        attributes => [
            {
                id            => 'title',
                data_type     => 'Title',
                mandatory     => 1,
            },
            {
                id            => 'children',
                data_type     => 'Object',
                mandatory     => 0,
            },
        ],
    },
    textfield => {
        name => 'Textfield',
        attributes => [
            {
                id            => 'text',
                data_type     => 'Text',
                mandatory     => 1,
            },
        ],
    },
});

my $root = $model->get_object($c, 1);
    my $source = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Source' },
    );
        my @texts = reverse map {
            $source->create_child(
                attribute => 'children',
                type      => 'textfield',
                data      => {
                    text => "$_",
                },
            );
        } reverse 1 .. 10;
    my $destination = $root->create_child(
        attribute => 'children',
        type      => 'folder',
        data      => { title => 'Destination' },
    );

source_in_order();

# move #1 text from source to destination
my $moving = shift @texts;
$moving->move_to(parent => $destination, parent_attr => 'children');
my @moved = $moving;

$_->refresh foreach @texts;
is_deeply [ map { $_->{sort_id} } @texts ], [ 1 .. @texts ];
is($moving->refresh->{sort_id}, 1);
source_in_order();

# move #3 text from source to destination
($moving) = splice @texts, 1, 1;
$moving->move_to(parent => $destination, parent_attr => 'children');
push @moved, $moving;
source_in_order();

$_->refresh foreach @moved;
is_deeply [ map { $_->{sort_id} } @moved ], [2, 1];

# move #5 text from source to destination after first
($moving) = splice @texts, 2, 1;
$moving->move_to(parent => $destination, parent_attr => 'children', after => $moved[1]);
push @moved, $moving;
source_in_order();

$_->refresh foreach @moved;
is_deeply [ map { $_->{sort_id} } @moved ], [3, 1, 2];

# move last text from source to destination after last
($moving) = pop @texts;
$moving->move_to(parent => $destination, parent_attr => 'children', after => $moved[0]);
push @moved, $moving;
source_in_order();

$_->refresh foreach @moved;
is_deeply [ map { $_->{sort_id} } @moved ], [3, 1, 2, 4];

is_deeply [ map { $_->property('text') } @moved ], [1, 3, 5, 10], 'sanity check moved texts';

done_testing;

sub source_in_order {
    $_->refresh foreach @texts;
    is_deeply
        [ map { $_->{sort_id} } @texts ],
        [ 1 .. @texts ],
        @texts . ' source texts have correct sort_id';
}
