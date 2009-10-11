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

=head2 default

Just throw a 404.

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    return $c->res->redirect($c->stash->{uri_raw} . 'index.html') if $c->req->uri->path =~ m!/\z!;

    $c->response->body( 'Page not found' );
    $c->response->status(404);

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
