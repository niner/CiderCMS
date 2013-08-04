package CiderCMS::Controller::Custom::Reservation;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head2 reserve

Reserve the displayed plane.

=cut

sub reserve : CiderCMS('reserve') {
    my ( $self, $c ) = @_;

    $c->detach('/user/login') unless $c->user;

    my $params = $c->req->params;
    $params->{type}        = 'reservation';
    $params->{parent_attr} = 'reservations';
    $params->{user}        = $c->user->get('name');
    if ($c->forward('/content/management/manage_add')) {
        return $c->res->redirect($c->stash->{context}->uri . '/reserve');
    }

    $_ = join ', ', @$_ foreach values %{ $c->stash->{errors} };

    my $content = $c->view('Petal')->render_template(
        $c,
        {
            %{ $c->stash },
            %$params,
            template => 'custom/reservation/reserve.zpt',
            uri_cancel => $c->stash->{context}->uri . '/cancel',
        },
    );

    $c->stash({
        template => 'index.zpt',
        content  => $content,
    });

    return;
}

=head2 cancel

Cancel the given reservation.

=cut

sub cancel : CiderCMS('cancel') Args(1) {
    my ($self, $c, $id) = @_;

    my $context = $c->stash->{context};
    my $reservation = $c->model('DB')->get_object($c, $id, $context->{level} + 1);
    if ($reservation->{parent} == $context->{id}) {
        $reservation->update({data => {cancelled_by => $c->user->get('name')}});
    }

    return $c->res->redirect($c->stash->{context}->uri . '/reserve');
}

1;
