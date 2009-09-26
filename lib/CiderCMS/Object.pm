package CiderCMS::Object;

use strict;
use warnings;

use Scalar::Util qw(weaken);

use CiderCMS::Attribute;
use CiderCMS::Attribute::String;

=head1 NAME

CiderCMS::Object - Content objects

=head1 SYNOPSIS

See L<CiderCMS>

=head1 DESCRIPTION

This class is the base for all content objects and provides the public API that can be used in templates.

=head1 METHODS

=head2 new({c => $c, type => 'type1', sort_id => 0, data => {}})

=cut

sub new {
    my ($class, $params) = @_;
    $class = ref $class if ref $class;

    my $c     = $params->{c};
    my $stash = $c->stash;
    my $type  = $params->{type};
    my $data  = $params->{data};

    my $self = bless {
        c          => $params->{c},
        type       => $type,
        sort_id    => $params->{sort_id} || 0,
        attr       => $stash->{types}{$type}{attr},
        attributes => $stash->{types}{$type}{attributes},
    }, $class;

    weaken($self->{c});

    foreach my $attr (@{ $self->{attributes} }) {
        my $id = $attr->{id};
        if (exists $data->{$id} and defined $data->{$id} and $data->{$id} ne '') {
            $self->{data}{$id} = $attr->{class}->new({c => $c, object => $self, id => $id, data => $data->{$id}});
        }
    }

    return $self;
}

=head2 edit_form($uri_action)

Renders the form for editing this object.

=cut

sub edit_form {
    my ($self, $uri_action) = @_;
}

=head2 insert()

Inserts the object into the database.

=cut

sub insert {
    my ($self) = @_;

    return $self->{c}->model('DB')->insert_object($self->{c}, $self);
}

=head2 get_dirty_columns()

Returns two array refs with column names and corresponding values.

=cut

sub get_dirty_columns {
    my ($self) = @_;

    my (@columns, @values);

    foreach (@{ $self->{attributes} }) {
        my $id = $_->{id};
        my $attr = $self->{data}{$id};

        if ($attr->db_type) {
            push @columns, $id;
            push @values, $attr->data;
        }
    }

    return \@columns, \@values;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
