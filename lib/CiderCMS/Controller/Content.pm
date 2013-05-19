package CiderCMS::Controller::Content;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CiderCMS::Controller::Content - Catalyst Controller

=head1 DESCRIPTION

Controller for initializing and displaying content according to the URI path.

=head1 METHODS

=head2 auto

Check user access to the context node.

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    my $objects = $c->stash->{parents};

    if ($objects and @$objects and not $objects->[-1]->user_has_access) {
        $c->detach($c->user ? '/user/access_denied' : '/user/login');
    }

    return 1;
}

=head2 index_html

Renders the page.

=cut

sub index_html : CiderCMS('index.html') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash({
        template => 'index.zpt',
        content  => $c->stash->{context}->render,
    });

    return;
}

sub index : CiderCMS('') Args(0) {
    my ($self, $c) = @_;

    return $self->index_html($c);
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
