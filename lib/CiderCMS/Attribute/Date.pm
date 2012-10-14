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

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
