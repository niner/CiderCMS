package CiderCMS::Attribute::Integer;

use strict;
use warnings;

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::Integer - Integer attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Simple integer attribute

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'integer';
}

=head2 set_data($data)

Sets this attributes data to the given value.

=cut

sub set_data {
    my ($self, $data) = @_;

    return $self->{data} = $data if defined $data and $data ne '';
    return $self->{data} = undef;
}

=head2 validate

Check if $data is a valid number.

=cut

sub validate {
    my ($self, $data) = @_;

    my $number = $data->{ $self->id };
    return 'missing' if $self->{mandatory} and (not defined $number or $number eq '');
    return 'invalid' if $number and $number =~ /\D/;
    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
