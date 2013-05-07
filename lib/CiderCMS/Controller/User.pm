package CiderCMS::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CiderCMS::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 login

Shows a login page.

=cut

sub login : Private {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    if ($username and $password) {
        if ($c->authenticate({name => $username, password => $password})) {
            return $c->res->redirect($c->req->param('referer') // $c->req->uri);
        }
        else {
            $c->stash({
                username => $username,
                message  => 'Invalid username/password',
            });
        }
    }

    $c->stash({
        referer  => $c->req->param('referer') // $c->req->uri,
        template => 'login.zpt',
    });

    return;
}


=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
