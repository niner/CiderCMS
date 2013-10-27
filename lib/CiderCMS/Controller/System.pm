package CiderCMS::Controller::System;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CiderCMS::Controller::System - Catalyst Controller

=head1 DESCRIPTION

Meta operations of the instance, e.g. everything not related to content manipulation.

=head1 METHODS

=head2 init

PathPart that sets up the current instance.

=cut

sub init : Chained('/') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $instance ) = @_;

    $c->stash->{instance} = $instance;

    my $model = $c->model('DB');
    $model->initialize($c);

    $c->stash({
        uri_manage_types   => $c->uri_for_instance('system/types'),
        uri_manage_content => $model->get_object($c, 1)->uri_management,
    });

    return;
}

=head2 create

Create a new CiderCMS instance, e.g. a new website.

=cut

sub create :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $valid = $c->form({
        required => [qw(id title)],
    });
    if ($valid) {
        $c->model('DB')->create_instance($c, scalar $valid->valid());
        $c->stash({ instance => $valid->valid('id') });
        return $c->res->redirect($c->uri_for_instance('manage'));
    }
    else {
        $c->stash({ template => 'system/create.zpt' });
    }

    return;
}

=head2 logout

Ends the user's session

=cut

sub logout : Local :Args(0) {
    my ( $self, $c ) = @_;

    $c->logout;

    return $c->res->redirect($c->req->referer) if $c->req->referer;
    return $c->res->body('User logged out');
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
