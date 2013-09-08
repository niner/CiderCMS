package CiderCMS::Attribute::Date;

use strict;
use warnings;

use DateTime;

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::Date - Date attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Simple date attribute

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'date';
}

=head2 set_data($data)

Sets this attributes data to the given value.

=cut

sub set_data {
    my ($self, $data) = @_;

    return $self->{data} = $data if $data;
    return $self->{data} = undef;
}

=head2 validate

=cut

sub validate {
    my ($self, $data) = @_;

    my $value = $data->{ $self->id };

    return
        $self->SUPER::validate($data),
        ($value and $value !~ /\A \d{4}-\d{2}-\d{2} \z/xm)
            ? 'invalid'
            : ();
}

=head2 filter_matches($value)

Returns true if this attribute matches the given filter value.
$value may be 'future' to check if this date lies in the future.

=cut

sub filter_matches {
    my ($self, $value) = @_;

    if ($value eq 'future') {
        return DateTime->now->ymd le $self->data;
    }

    return;
}

=head2 is_today()

Returns true if the stored day is today.

=cut

sub is_today {
    my ($self, $value) = @_;

    return DateTime->now->ymd eq $self->data;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
