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

    my $validation = $c->form(
        required => [qw(date start end)],
        optional => [qw(info)],
    );

    if ($validation) {
        my $valid = $validation->valid;

        $c->stash->{context}->new_child(
            attribute => 'reservations',
            type      => 'reservation',
            data      => {
                %$valid,
                user => $c->user->get('name'),
            },
        )->insert;

        return $c->res->redirect($c->stash->{context}->uri . '/reserve');
    }

    my $content = $c->view('Petal')->render_template(
        $c,
        {
            %{ $c->stash },
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
        $reservation->delete_from_db;
    }

    return $c->res->redirect($c->stash->{context}->uri . '/reserve');
}

1;
