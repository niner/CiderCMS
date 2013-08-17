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

    my $params  = $c->req->params;
    my $referer = delete $params->{referer};

    if (%$params) {
        if ($c->authenticate($params)) {
            return $c->res->redirect($referer // $c->stash->{uri_raw});
        }
        else {
            $c->stash({
                %$params,
                message  => 'Invalid username/password',
            });
        }
    }

    $c->stash({
        referer  => $referer // $c->stash->{uri_raw},
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
