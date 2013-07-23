package CiderCMS::Attribute::String;

use strict;
use warnings;

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::String - String attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Simple string attribute

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'varchar';
}

=head2 filter_matches($value)

Returns true if this attribute matches the given filter value.
For now simply matches for equality.

=cut

sub filter_matches {
    my ($self, $value) = @_;

    return not defined $self->data unless defined $value;
    return unless defined $self->data;

    return $value eq $self->data;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
