package CiderCMS::Attribute;

use strict;
use warnings;

use Scalar::Util qw(weaken);

=head1 NAME

CiderCMS::Attribute - Base class for attributes

=head1 SYNOPSIS

See L<CiderCMS::Object>

=head1 DESCRIPTION

Base class for all object attributes.

=head1 METHODS

=head2 new({c => $c, object => $object, id => 'attr1', data => 'foo'})

=cut

sub new {
    my ($class, $params) = @_;
    $class = ref $class if ref $class;

    my $self = bless $params, $class;

    weaken($self->{c});
    weaken($self->{object});

    return $self;
}

=head2 db_type

Returns the DB data type (if any) for this attribute

=cut

sub db_type {
    return;
}

=head2 data

Returns the data

=cut

sub data {
    my ($self) = @_;
    return $self->{data};
}

=head2 input_field

Renders an input field for this attribute.
Uses this attribute's class name for selecting the template.
Override for anything more complicated than a simple input field.

=cut

sub input_field {
    my ($self) = @_;

    my $c = $self->{c};

    my $template = ref $self;
    $template =~ s/CiderCMS::Attribute:://;
    $template = lc $template;

    $c->view()->render_template($c, {
        template => "attributes/$template.zpt",
        self => $self,
    });
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
