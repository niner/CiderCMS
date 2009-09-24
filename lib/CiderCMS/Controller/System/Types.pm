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

    return;
}

=head2 create

Create a new type

=cut

sub create : PathPart('system/create_type') Chained('/system/init') {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;

    if (delete $params->{save}) {
        $c->model('DB')->create_type($c, $params);
        return $c->res->redirect($c->uri_for_instance("system/types/$params->{id}/edit"));
    }

    $c->stash({
        template => 'system/types/create.zpt',
        type     => $params,
    });

    return;
}

=head2 setup_type

Chain part setting up a requested type

=cut

sub setup_type : PathPart('system/types') CaptureArgs(1) Chained('/system/init') {
    my ( $self, $c, $id ) = @_;

    $c->stash({
        type => $c->stash->{types}{$id},
    });

    return;
}

=head2 edit

Edit an existing type.

=cut

sub edit : PathPart('') Chained('setup_type') {
    my ( $self, $c ) = @_;

    $c->stash({
        template          => 'system/types/edit.zpt',
        uri_save          => $c->uri_for('save'),
        uri_new_attribute => $c->uri_for('new_attribute'),
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
