package CiderCMS::Attribute::Time;

use strict;
use warnings;

use DateTime;

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

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
