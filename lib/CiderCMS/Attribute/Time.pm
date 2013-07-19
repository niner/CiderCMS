package CiderCMS::Attribute::Time;

use strict;
use warnings;

use POSIX qw(strftime);

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::Time - Time attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Simple date attribute

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'time';
}

=head2 format($format)

Returns a representation of the stored time according to the given format.
See 'strftime Patterns' in L<DateTime> for details about the format.

=cut

sub format {
    my ($self, $format) = @_;

    my ($h, $m, $s) = split /:/, $self->data;
    return strftime($format, $s, $m, $h, 0, 0, 0);
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
