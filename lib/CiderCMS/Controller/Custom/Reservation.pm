package CiderCMS::Controller::Custom::Reservation;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use DateTime::Format::ISO8601;

=head2 reserve

Reserve the displayed plane.

=cut

sub reserve : CiderCMS('reserve') {
    my ( $self, $c ) = @_;

    $c->detach('/user/login') unless $c->user;

    my $params = $c->req->params;
    my $save   = delete $params->{save};
    my $object = $c->stash->{context}->new_child(
        attribute => 'reservations',
        type      => 'reservation',
    );
    my $time_limit = $c->stash->{context}->property('reservation_time_limit', undef);
    $object->update_data($params);

    my $errors = {};
    if ($save) {
        $errors = $object->validate;
        unless ($errors) {
            if (defined $time_limit) {
                my $limit = DateTime->now(time_zone => 'local')
                    ->set_time_zone('floating')
                    ->add(hours => $time_limit);

                $params->{start} = sprintf '%02i:%02i', split /:/, $params->{start};
                my $start = DateTime::Format::ISO8601->new(base_datetime => $limit)->parse_datetime(
                    "$params->{date}T$params->{start}"
                );

                $errors->{date} = ['too close'] if $start->datetime lt $limit->datetime;
            }
        }
        unless ($errors) {
            $object->insert;
            return $c->res->redirect($c->stash->{context}->uri . '/reserve');
        }

        $_ = join ', ', @$_ foreach values %$errors;
    }
    else {
        $object->init_defaults;
    }

    $c->stash->{reservation} = 1;
    my $content = $c->view('Petal')->render_template(
        $c,
        {
            user       => $c->user->get('name'),
            %{ $c->stash },
            %$params,
            template   => 'custom/reservation/reserve.zpt',
            uri_cancel => $c->stash->{context}->uri . '/cancel',
            errors     => $errors,
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
