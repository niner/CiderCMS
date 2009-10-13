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

Sets up context information according to the current path

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    my $path = $c->req->path;
    $path =~ s!/+!/!g;
    my @path = split m!/!, $path;

    my $instance = shift @path;
    unshift @path, '';
    $c->stash->{instance} = $instance;

    my $filename = pop @path; #FIXME what if there is no file name and no trailing slash?

    my $model = $c->model('DB');
    $model->initialize($c);

    my @objects = $model->traverse_path($c, \@path);

    $c->stash({
        parents => \@objects,
        context => $objects[-1],
        site    => $objects[0],
    });

    return 1;
}

=head2 index

Renders the page.

=cut

sub index : Regex('/(?:index\.html)?$') {
    my ( $self, $c ) = @_;

    $c->stash({
        template => 'index.zpt',
        content  => $c->stash->{context}->render,
    });
}


=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
