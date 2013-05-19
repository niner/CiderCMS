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

=head2 not_found

Just throw a 404.

=cut

sub not_found :Path {
    my ( $self, $c ) = @_;

    my $dispatch_error = $c->stash->{dispatch_error} // 'Page not found';
    $dispatch_error =~ s/\n[^\n]*\z//xm;
    $c->response->body($dispatch_error);
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
