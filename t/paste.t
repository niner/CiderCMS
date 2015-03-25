use strict;
use warnings;
use utf8;

use CiderCMS::Test (test_instance => 1, mechanize => 1);
use Test::More;

CiderCMS::Test->populate_types({
    CiderCMS::Test->std_folder_type,
    CiderCMS::Test->std_textfield_type,
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

my $paste = URI->new($destination->uri . '/manage_paste');
$paste->query_form(
    attribute => 'children',
    after     => '',
    id        => [ map { $_->id } @texts[1, 3, 5] ],
);
$mech->get($paste);

my @children = $destination->attribute('children')->data;
is(scalar @children, 3);
is(join(', ', map { $_->property('text') } @children), '2, 4, 6');

done_testing;
