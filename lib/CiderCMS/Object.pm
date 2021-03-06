package CiderCMS::Object;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use List::MoreUtils qw(any none);
use File::Path qw(mkpath);
use File::Copy qw(move);
use Carp qw(croak);

use CiderCMS::Attribute;

=head1 NAME

CiderCMS::Object - Content objects

=head1 SYNOPSIS

See L<CiderCMS>

=head1 DESCRIPTION

This class is the base for all content objects and provides the public API that can be used in templates.

=head1 METHODS

=head2 new({c => $c, id => 2, type => 'type1', parent => 1, parent_attr => 'children', sort_id => 0, data => {}})

=cut

sub new {
    my ($class, $params) = @_;
    $class = ref $class if ref $class;

    my $c     = $params->{c};
    my $stash = $c->stash;
    my $type  = $params->{type};
    my $data  = $params->{data};

    my $self = bless {
        c           => $params->{c},
        id          => $params->{id},
        parent      => $params->{parent},
        parent_attr => $params->{parent_attr},
        level       => $params->{level},
        type        => $type,
        sort_id     => $params->{sort_id} || 0,
        dcid        => $params->{dcid},
        attr        => $stash->{types}{$type}{attr},
        attributes  => $stash->{types}{$type}{attributes},
    }, $class;

    weaken($self->{c});

    foreach my $attr (@{ $self->{attributes} }) {
        my $id = $attr->{id};
        $self->{data}{$id} = $attr->{class}->new({c => $c, object => $self, data => $data->{$id}, %$attr});
    }

    return $self;
}

=head2 object_by_id($id)

Returns an object for the given ID

=cut

sub object_by_id {
    my ($self, $id) = @_;

    return $self->{c}->model('DB')->get_object($self->{c}, $id);
}

=head2 id

Returns this object's id.

=cut

sub id {
    my ($self) = @_;

    return $self->{id};
}

=head2 type

Returns the type info for this object.

For example:
    {
        id           => 'type1',
        name         => 'Type 1',
        page_element => 0,
        attributes   => [
            # same as {attrs}{attr1}
        ],
        attr         => {
            attr1 => {
                type          => 'type1',
                class         => 'CiderCMS::Attribute::String',
                id            => 'attr1',
                name          => 'Attribute 1',
                sort_id       => 0,
                data_type     => 'String',
                repetitive    => 0,
                mandatory     => 1,
                default_value => '',
            },
        },
    },

=cut

sub type {
    my ($self) = @_;
    return $self->{c}->stash->{types}{$self->{type}};
}

=head2 property($property)

Returns the data of the named attribute

=cut

sub property {
    my ($self, $property, $default) = @_;

    unless (exists $self->{data}{$property}) {
        return $default if @_ == 3;
        croak "unknown property $property";
    }
    return $self->{data}{$property}->data;
}

=head2 set_property($property, $data)

Sets the named attribute to the given value

=cut

sub set_property {
    my ($self, $property, $data) = @_;

    return $self->{data}{$property}->set_data($data);
}

=head2 attribute($attribute)

Returns the CiderCMS::Attribute object for the named attribute

=cut

sub attribute {
    my ($self, $attribute) = @_;

    return unless exists $self->{data}{$attribute};
    return $self->{data}{$attribute};
}

=head2 update_data($data)

Updates this object's data from a hashref.

=cut

sub update_data {
    my ($self, $data) = @_;

    foreach (values %{ $self->{data} }) {
        $_->set_data_from_form($data);
    }

    return;
}

=head2 init_defaults()

Initialize this object's data to the attributes' default values.

=cut

sub init_defaults {
    my ($self) = @_;

    $_->init_default foreach values %{ $self->{data} };

    return;
}

=head2 parent

Returns the parent of this object, if any.

=cut

sub parent {
    my ($self) = @_;

    return unless $self->{parent};

    return $self->{c}->model('DB')->get_object($self->{c}, $self->{parent}, $self->{level} - 1);
}

=head2 parents

Returns the parent chain of this object including the object itself.

=cut

sub parents {
    my ($self) = @_;

    my $parent = $self;
    my @parents = $parent;
    unshift @parents, $parent while $parent = $parent->parent;

    return \@parents;
}

=head2 parent_by_level($level)

Returns the parent at a certain level.
The site object is at level 0.

=cut

sub parent_by_level {
    my ($self, $level) = @_;

    return if $self->{level} < $level; # already on a lower level

    my $parent = $self;
    while ($parent) {
        return $parent if $parent->{level} == $level;
        $parent = $parent->parent;
    }

    return;
}

=head2 children()

Returns the children of this object regardless to which attribute they belong.
Usually one should use $object->property('my_attribute') to only get the children of a certain attribute.

Returns a list in list context and an array ref in scalar context.

=cut

sub children {
    my ($self) = @_;

    return $self->{c}->model('DB')->object_children($self->{c}, $self);
}

=head2 uri()

Returns an URI without a file name for this object

=cut

sub uri {
    my ($self) = @_;

    my $parent = $self->parent;
    my $dcid = ($self->{dcid} // $self->{id});

    return ( ($parent ? $parent->uri : $self->{c}->uri_for_instance()) . ($dcid ? "/$dcid" : '') );
}

=head2 uri_index()

Returns an URI to the first object in this subtree that contains page elements.
If none does, return the URI to the first child.

=cut

sub uri_index {
    my ($self) = @_;

    my @children = $self->children;
    if (not @children or any { $_->type->{page_element} } @children) { # we contain no children at all or page elements
        return $self->uri . '/index.html';
    }
    else {
        return $children[0]->uri_index;
    }
}

=head2 uri_management()

Returns an URI to the management interface for this object

=cut

sub uri_management {
    my ($self) = @_;

    return $self->uri . '/manage';
}

=head2 uri_static()

Returns an URI for static file for this object

=cut

sub uri_static {
    my ($self) = @_;

    my $parent = $self->parent;
    return ( ($parent ? $parent->uri_static : $self->{c}->uri_static_for_instance()) . "/$self->{id}" );
}

=head2 fs_path()

Returns the file system path to this node

=cut

sub fs_path {
    my ($self) = @_;

    my $parent = $self->parent;
    return ( ($parent ? $parent->fs_path : $self->{c}->fs_path_for_instance()) . "/$self->{id}" );
}

=head2 edit_form($errors)

Renders the form for editing this object.
The optional $errors may be a hash reference with error messages for attributes.

=cut

sub edit_form {
    my ($self, $errors) = @_;

    $errors //= {};
    my $c = $self->{c};

    return $c->view()->render_template($c, {
        %{ $c->stash },
        template   => 'edit.zpt',
        self       => $self,
        attributes => [
            map {
                $self->{data}{$_->{id}}->input_field($errors->{$_->{id}})
            } @{ $self->{attributes} },
        ],
    });
}

=head2 render()

Returns an HTML representation of this object.

=cut

sub render {
    my ($self) = @_;

    my $c = $self->{c};

    return $c->view()->render_template($c, {
        %{ $c->stash },
        template => "types/$self->{type}.zpt",
        self     => $self,
    });
}

=head2 validate($data)

Validate the given data.
Returns a hash containing messages for violated constraints:
    {
        attr1 => ['missing'],
        attr2 => ['invalid', 'wrong'],
    }

=cut

sub validate {
    my ($self, $data) = @_;

    my %results;
    foreach (values %{ $self->{data} }) {
        my @result = $_->validate($data);
        $results{ $_->{id} } = \@result if @result;
    }

    return \%results if keys %results;
    return;
}

=head2 prepare_attributes()

Prepares attributes for insert and update operations.

=cut

sub prepare_attributes {
    my ($self) = @_;

    foreach (values %{ $self->{data} }) {
        $_->prepare_update();
    }

    return;
}

=head2 update_attributes()

Runs update operation on attributes after inserts and updates.

=cut

sub update_attributes {
    my ($self) = @_;

    foreach (values %{ $self->{data} }) {
        $_->post_update();
    }

    return;
}

=head2 insert({after => $after})

Inserts the object into the database.

=cut

sub insert {
    my ($self, $params) = @_;

    if ($params->{data}) {
        $self->update_data(delete $params->{data});
    }

    $self->prepare_attributes;

    my $result = $self->{c}->model('DB')->insert_object($self->{c}, $self, $params);

    $self->update_attributes;

    return $result;
}

=head2 update()

Updates the object in the database.

=cut

sub update {
    my ($self, $params) = @_;

    if ($params->{data}) {
        $self->update_data($params->{data});
    }

    $self->prepare_attributes;

    my $result = $self->{c}->model('DB')->update_object($self->{c}, $self);

    $self->update_attributes;

    return $result;
}

=head2 delete_from_db()

Deletes the object and it's children.

=cut

sub delete_from_db {
    my ($self) = @_;

    foreach ($self->children) {
        $_->delete_from_db;
    }

    return $self->{c}->model('DB')->delete_object($self->{c}, $self);
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
            push @values, $attr->{data}; #TODO introduce an $attr->raw_data
        }
    }

    return \@columns, \@values;
}

=head2 move_to(parent => $parent, parent_attr => $parent_attr, after => $after)

Moves this object (and it's subtree) to a new parent and or sort position

=cut

sub move_to {
    my ($self, %params) = @_;

    my $old_fs_path = $self->fs_path;

    my $result = $self->{c}->model('DB')->move_object($self->{c}, $self, \%params);

    if (-e $old_fs_path) {
        my $new_fs_path = $self->fs_path;

        mkpath $self->parent->fs_path if $self->{parent};
        move $old_fs_path, $new_fs_path;
    }

    return $result;
}

=head2 refersh()

Reloads this object from the database.

=cut

sub refresh {
    my ($self) = @_;

    my $fresh = $self->{c}->model('DB')->get_object($self->{c}, $self->{id});
    %$self = %$fresh;
    return $self;
}

=head2 new_child(attribute => $attribute, type => $type, data => $data)

Creates a child object in memory for the given attribute.

=cut

sub new_child {
    my ($self, %params) = @_;

    $params{c}           = $self->{c};
    $params{parent}      = $self->{id};
    $params{level}       = $self->{level};
    $params{parent_attr} = delete $params{attribute};

    croak "Invalid attribute: $params{parent_attr}"
        unless exists $self->{data}{ $params{parent_attr} };

    return CiderCMS::Object->new(\%params);
}

=head2 create_child(attribute => $attribute, type => $type, data => $data)

Creates a child object in the database for the given attribute.

=cut

sub create_child {
    my ($self, %params) = @_;

    # Don't give data to new_child. Instead give it to insert so it gets treated like
    # data subitted through the management UI.
    my $data = delete $params{data};
    my $child = $self->new_child(%params);
    $child->insert({data => $data});
    return $child;
}

=head2 user_has_access

Returns whether the currently logged in user has access to this folder and all
parent folders.

=cut

sub user_has_access {
    my ($self) = @_;

    my $user = $self->{c}->user;
    return 1 if $user;
    return none { $_->property('restricted', 0) } @{ $self->parents };
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
