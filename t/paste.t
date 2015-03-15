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

$_->refresh foreach @texts;
is_deeply [ map { $_->{sort_id} } @texts ], [ 1 .. @texts ];

my $moving = shift @texts;
$moving->move_to(parent => $destination, parent_attr => 'children');
my @moved = $moving;

$_->refresh foreach @texts;
is_deeply [ map { $_->{sort_id} } @texts ], [ 1 .. @texts ];
is($moving->refresh->{sort_id}, 1);

($moving) = splice @texts, 1, 1;
$moving->move_to(parent => $destination, parent_attr => 'children');
push @moved, $moving;

$_->refresh foreach @moved;
is_deeply [ map { $_->{sort_id} } @moved ], [2, 1];

done_testing;
