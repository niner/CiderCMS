package CiderCMS::Attribute::Object;

use strict;
use warnings;

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

    return $self->{c}->model('DB')->object_children($self->{c}, $self->{object}, $self->{id});
}

=head2 input_field

Renders a list of children for this attribute with links for adding more.

=cut

sub input_field {
    my ($self) = @_;

    my $c = $self->{c};

    return $c->view()->render_template($c, {
        %{ $c->stash },
        template      => "attributes/object.zpt",
        addable_types => [values %{ $c->stash->{types} }],
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
