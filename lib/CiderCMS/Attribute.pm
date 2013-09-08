package CiderCMS::Attribute;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use Module::Pluggable require => 1, search_path => [__PACKAGE__];

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

=head2 id

Returns this attribute's id.

=cut

sub id {
    my ($self) = @_;

    return $self->{id};
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

=head2 set_data($data)

Sets this attribute's data to the given value.

=cut

sub set_data {
    my ($self, $data) = @_;

    return $self->{data} = $data;
}

=head2 set_data_from_form($data)

Sets this attribute's data from submitted form data.

=cut

sub set_data_from_form {
    my ($self, $data) = @_;

    return unless exists $data->{ $self->id };

    return $self->set_data($data->{ $self->id });
}

=head2 prepare_update

Preparations for updating this attribute.
Default implementation does nothing.

=cut

sub prepare_update {
}

=head2 post_update

Does post update work for this attribute.
Default implementation does nothing.

=cut

sub post_update {
}

=head2 meta_data

Returns this attribute's meta data.
See L<CiderCMS::Model::DB::intitialize> for a description of this data.

=cut

sub meta_data {
    my ($self) = @_;

    return $self->{object}{attr}{ $self->{id} };
}

=head2 init_default

Sets this attribute to its default value.

=cut

sub init_default {
    my ($self) = @_;

    $self->set_data($self->meta_data->{default_value});

    return;
}

=head2 validate

Validates this attribute's data.
Default implementation just checks if mandatory data is present.

=cut

sub validate {
    my ($self, $data) = @_;

    return 'missing' if $self->{mandatory} and not defined $data->{ $self->id };
    return;
}

=head2 filter_matches($value)

Returns true if this attribute matches the given filter value.

=cut

sub filter_matches {
    my ($self, $value) = @_;

    return;
}

=head2 input_field($errors)

Renders an input field for this attribute.
Uses this attribute's class name for selecting the template.
Override for anything more complicated than a simple input field.

=cut

sub input_field {
    my ($self, $errors) = @_;

    $errors //= [];
    my $c = $self->{c};

    my $template = ref $self;
    $template =~ s/CiderCMS::Attribute:://xm;
    $template = lc $template;

    return $c->view()->render_template($c, {
        template => "attributes/$template.zpt",
        self     => $self,
        errors   => join(', ', @$errors),
    });
}

=head2 attribute_types

Returns an array containing the names of all available attribute types.

=cut

my @attribute_types = map { /CiderCMS::Attribute::(.*)/xm } __PACKAGE__->plugins;

sub attribute_types {
    return @attribute_types;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
