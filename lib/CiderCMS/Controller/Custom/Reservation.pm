package CiderCMS::Controller::Custom::Reservation;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head2 reserve

Reserve the displayed plane.

=cut

sub reserve : CiderCMS('reserve') {
    my ( $self, $c ) = @_;

    my $validation = $c->form(
        required => [qw(date)],
    );

    if ($validation) {
        my $valid = $validation->valid;

        $c->stash->{context}->new_child(
            attribute => 'reservations',
            type      => 'reservation',
            data      => {
                %$valid,
                #user => $c->user->name,
            },
        )->insert;
    }

    my $content = $c->view('Petal')->render_template(
        $c,
        {
            %{ $c->stash },
            template => 'custom/reservation/reserve.zpt',
        },
    );

    $c->stash({
        template => 'index.zpt',
        content  => $content,
    });

    return;
}

1;
