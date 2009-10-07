package CiderCMS::Object;

use strict;
use warnings;

use Scalar::Util qw(weaken);

use CiderCMS::Attribute;
use CiderCMS::Attribute::String;
use CiderCMS::Attribute::Object;

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
        id         => $params->{id},
        parent     => $params->{parent},
        type       => $type,
        sort_id    => $params->{sort_id} || 0,
        dcid       => $params->{dcid} || '',
        attr       => $stash->{types}{$type}{attr},
        attributes => $stash->{types}{$type}{attributes},
    }, $class;

    weaken($self->{c});

    foreach my $attr (@{ $self->{attributes} }) {
        my $id = $attr->{id};
        $self->{data}{$id} = $attr->{class}->new({c => $c, object => $self, data => $data->{$id}, %$attr});
    }

    return $self;
}

=head2 property($property)

=cut

sub property {
    my ($self, $property) = @_;

    return $self->{data}{$property}->data;
}

=head2 parent

Returns the parent of this object, if any.

=cut

sub parent {
    my ($self) = @_;

    return unless $self->{parent};

    $self->{c}->model('DB')->get_object($self->{c}, $self->{parent});
}

=head2 children

Returns the children of this object, if any.

=cut

sub children {
    my ($self) = @_;

    return $self->{c}->model('DB')->object_children($self->{c}, $self);
}

=head2 uri

Returns an URI without a file name for this object

=cut

sub uri {
    my ($self) = @_;

    my $parent = $self->parent;
    my $dcid = ($self->{dcid} // $self->{id});
    return ( ($parent ? $parent->uri : $self->{c}->uri_for_instance()) . ($dcid ? "/$dcid" : '') );
}

=head2 uri_index()

Returns an URI to the index action for this object

=cut

sub uri_index {
    my ($self) = @_;

    return $self->uri . '/index.html';
}

=head2 uri_management()

Returns an URI to the management interface for this object

=cut

sub uri_management {
    my ($self) = @_;

    return $self->uri . '/manage';
}

=head2 edit_form($uri_action)

Renders the form for editing this object.

=cut

sub edit_form {
    my ($self, $uri_action) = @_;

    my $c = $self->{c};

    return $c->view()->render_template($c, {
        %{ $c->stash },
        template   => 'edit.zpt',
        uri_action => $uri_action,
        self       => $self,
        attributes => [
            map $self->{data}{$_->{id}}->input_field, @{ $self->{attributes} },
        ],
    });
}

=head2 render()

Returns an HTML representation of this object.

=cut

sub render {
    my ($self) = @_;

    my $c = $self->{c};

    $c->view()->render_template($c, {
        %{ $c->stash },
        template => "types/$self->{type}.zpt",
        self     => $self,
    });
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
