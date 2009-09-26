package CiderCMS::Attribute::String;

use strict;
use warnings;

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::String - Base class for attributes

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

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
