package CiderCMS::Controller::System::Types;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CiderCMS::Controller::System::Types - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

List all available types.

=cut

sub index : PathPart('system/types') Chained('/system/init') {
    my ( $self, $c ) = @_;

    $_->{uri_edit} = $c->uri_for_instance("system/types/$_->{id}/edit") foreach values %{ $c->stash->{types} };

    $c->stash({
        template   => 'system/types/index.zpt',
        type_list  => [sort {$a->{name} cmp $b->{name}} values %{ $c->stash->{types} }],
        uri_create => $c->uri_for_instance('system/create_type'),
    });
}


=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
