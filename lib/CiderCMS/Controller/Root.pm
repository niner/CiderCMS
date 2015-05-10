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

sub not_found :Private {
    my ( $self, $c ) = @_;

    my $dispatch_error = $c->stash->{dispatch_error} // 'Page not found';
    $dispatch_error =~ s/\n[^\n]*\z//xm;
    $c->response->body($dispatch_error);
    $c->response->status(404);

    return;
}

sub default : Path {
    my ($self, $c) = @_;

    my $path = $c->config->{root} . '/instances/' . $c->req->path;

    if (-e $path and -f $path and -s $path) {
        return $c->serve_static_file($path);
    }

    $c->forward($c->controller->action_for('not_found'));
}


=head2 render

Attempt to render a view, if needed.

=cut

sub render : ActionClass('RenderView') {
    return;
}

=head2 end

Render a view or display a custom error page in case of an error happened.

=cut

sub end : Private {
    my ( $self, $c ) = @_;

    $c->forward('render');

    if (@{ $c->error }) {
        $c->res->status(500);

        warn join "\n", @{ $c->error };

        # avoid disclosure of the application's path
        my @errors = @{ $c->error };
        my $home = $c->config->{home};
        s!$home/!!g foreach @errors;

        $c->stash({
            template => 'error.zpt',
            errors   => \@errors,
        });

        $c->forward('render');

        $c->clear_errors;
    }

    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
