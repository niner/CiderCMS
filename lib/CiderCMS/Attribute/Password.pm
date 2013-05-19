package CiderCMS::Attribute::Password;

use strict;
use warnings;

use base qw(CiderCMS::Attribute::String);

use Digest::SHA qw(sha256_hex);

=head1 NAME

CiderCMS::Attribute::Password - Password attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Password attribute. Stores the password securely (using SHA-256).

=head1 METHODs

=head2 set_data($data)

Sets this attributes data to the given value.

=cut

sub set_data {
    my ($self, $data) = @_;

    return $self->{data} = sha256_hex($data);
}

=head2 prepare_update()

=cut

sub prepare_update {
    my ($self) = @_;

    $self->set_data($self->data);

    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;