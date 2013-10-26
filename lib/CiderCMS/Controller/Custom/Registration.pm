package CiderCMS::Controller::Custom::Registration;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head2 register

Register a new user.

=cut

sub register : CiderCMS('register') {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;
    my $object = $c->stash->{context}->parent->new_child(
        attribute => 'children',
        type      => 'user',
    );

    my $errors = $object->validate($params);
    if ($errors) {
        $c->stash({
            %$params,
            errors => $errors,
        });
        $c->forward('/content/index_html');
    }
    else {
        $object->insert({data => $params});
        return $c->res->redirect($c->stash->{context}->property('success')->[0]->uri_index);
    }

    return;
}

1;

