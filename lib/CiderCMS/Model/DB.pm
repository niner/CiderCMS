package CiderCMS::Model::DB;

use strict;
use base 'Catalyst::Model::DBI';

__PACKAGE__->config(
    dsn           => '',
    user          => '',
    password      => '',
    options       => {},
);

=head1 NAME

CiderCMS::Model::DB - DBI Model Class

=head1 SYNOPSIS

See L<CiderCMS>

=head1 DESCRIPTION

DBI Model Class.

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
