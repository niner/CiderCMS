package CiderCMS::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

CiderCMS::Controller::Root - Root Controller for CiderCMS

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body( $c->welcome_message );

    return;
}

=head2 default

Tries to render a custom layout. Throws a 404 if none could be found.

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);

    return;
}

=head2 manage

Shows the management interface.

=cut

sub manage :Regex('/manage\z') {
    my ( $self, $c) = @_;

    $c->stash({ template => 'manage.zpt' });

    return;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
