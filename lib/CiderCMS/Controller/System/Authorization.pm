package CiderCMS::Controller::System::Authorization;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CiderCMS::Controller::System::Authorization - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 list

List users.

=cut

sub list : PathPart('system/authorization') Chained('/system/init') {
    my ( $self, $c ) = @_;

    $c->stash({
        template   => 'system/authorization/index.zpt',
        users      => $c->model('DB')->users,
        user       => {},
        uri_create => $c->uri_for_instance('system/authorization/create'),
    });

    return;
}

=head2 create

Create a new user

=cut

sub create : PathPart('system/authorization/create') Chained('/system/init') {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;

    if (delete $params->{save}) {
        my $id = $c->model('DB')->create_user($c, $params);
        return $c->res->redirect($c->uri_for_instance("system/authorization"));
    }

    $c->stash({
        template => 'system/authorization/create.zpt',
        user     => $params,
    });

    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
