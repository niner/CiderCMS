package CiderCMS::Attribute::Object;

use strict;
use warnings;

use List::Util qw(shuffle);
use List::MoreUtils qw(all);
use CiderCMS::Search;

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::Object - Object attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Attribute representing a slot for child objects

=head1 METHODS

=head2 data

Returns the child objects for this attribute

=cut

sub data {
    my ($self) = @_;

    return wantarray ? @{ $self->{children} } : $self->{children} if $self->{children};

    $self->{children} = [ $self->{c}->model('DB')->object_children($self->{c}, $self->{object}, $self->{id}) ];

    return wantarray ? @{ $self->{children} } : $self->{children};
}

=head2 pages

Returns all child objects that are pages

=cut

sub pages {
    my ($self) = @_;

    my @pages = grep {not $_->type->{page_element}} $self->data;
    return wantarray ? @pages : \@pages;
}

=head2 objects_by_type($type)

Returns the child objects conforming to the given $type.

=cut

sub objects_by_type {
    my ($self, $type) = @_;

    my @objects = grep {$_->{type} eq $type}
        $self->{c}->model('DB')->object_children($self->{c}, $self->{object}, $self->{id});

    return wantarray ? @objects : \@objects;
}

=head2 filtered(%filters)

Returns the child objects conforming to the given filters.
Filters may be:
    type  => 'some_type_id',
    attr1 => 'value of attribute 1',
    attr2 => 'value of attribute 2'

=cut

sub filtered {
    my ($self, %filters) = @_;

    my @objects =
        $self->{c}->model('DB')->object_children($self->{c}, $self->{object}, $self->{id});

    if (exists $filters{type}) {
        @objects = grep {$_->{type} eq $filters{type}} @objects;
        delete $filters{type};
    }

    @objects = grep {
        my $object = $_;
        all {
            $object->attribute($_)->filter_matches($filters{$_})
        } keys %filters,
    } @objects;

    return wantarray ? @objects : \@objects;
}

=head2 search(%filters)

Returns a search object containing the given filters.
Filters may be:
    type  => 'some_type_id',
    attr1 => 'value of attribute 1',
    attr2 => 'value of attribute 2'

=cut

sub search {
    my ($self, @filters) = @_;

    return CiderCMS::Search->new({
        c           => $self->{c},
        parent      => $self->{object},
        parent_attr => $self->{id},
        filters     => \@filters,
    });
}

=head2 random($count)

Returns a random selection of child objects for this attribute

=cut

sub random {
    my ($self, $count) = @_;

    my @children = shuffle $self->data;

    @children = @children[0 .. $count - 1] if $count and @children > $count;

    return wantarray ? @children : \@children;
}

=head2 previous($obj)

Returns the previous object to the given one in the children list.

=cut

sub previous {
    my ($self, $obj) = @_;

    my $prev;
    foreach ($self->data) {
        return $prev if $_->{id} eq $obj->{id};
        $prev = $_;
    }

    return;
}

=head2 next($obj)

Returns the next object to the given one in the children list.

=cut

sub next { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $obj) = @_;

    my $current;
    foreach ($self->data) {
        return $_ if $current;
        $current = $_ if $_->{id} eq $obj->{id};
    }

    return;
}

=head2 input_field

Renders a list of children for this attribute with links for adding more.

=cut

sub input_field {
    my ($self) = @_;

    my $c = $self->{c};

    return $c->view()->render_template($c, {
        %{ $c->stash },
        template      => 'attributes/object.zpt',
        addable_types => [sort { $a->{name} cmp $b->{name} } values %{ $c->stash->{types} }],
        children      => scalar $self->data,
        self          => $self,
    });
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
