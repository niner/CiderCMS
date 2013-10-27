package CiderCMS::Controller::Custom::Reservation;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use DateTime::Format::ISO8601;
use DateTime::Span;
use Hash::Merge qw(merge);

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

    my $errors = {};
    if ($save) {
        $errors = $object->validate($params);
        unless ($errors) {
            $params->{start_time} = sprintf '%02i:%02i', split /:/, $params->{start_time};
            my $start = DateTime::Format::ISO8601->new(
                base_datetime => DateTime->now(time_zone => 'floating'),
            )->parse_datetime(
                "$params->{start_date}T$params->{start_time}"
            );

            $errors = merge(
                $self->check_time_limit($c, $start),
                $self->check_conflicts($c, $start, $params->{end}),
            );
        }
        unless ($errors) {
            $object->insert({data => $params});
            return $c->res->redirect($c->stash->{context}->uri . '/reserve');
        }

        $_ = join ', ', @$_ foreach values %$errors;
    }
    else {
        $object->init_defaults;
    }

    $c->stash->{reservation} = 1;
    $c->stash->{reserve} = 1;
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

=head3 check_time_limit($c, $start)

=cut

sub check_time_limit {
    my ($self, $c, $start) = @_;

    my $time_limit = $c->stash->{context}->property('reservation_time_limit', undef);
    return unless $time_limit;

    my $limit = DateTime->now(time_zone => 'local')
        ->set_time_zone('floating')
        ->add(hours => $time_limit);

    return {start => ['too close']} if $start->datetime lt $limit->datetime;

    return;
}

=head3 check_conflicts($c, $start)

=cut

sub check_conflicts {
    my ($self, $c, $start, $end) = @_;

    my $reservations = $c->stash->{context}->attribute('reservations');

    my $new = create_datetime_span($start, $end);

    foreach my $existing (@{ $reservations->filtered(cancelled_by => undef) }) {
        my $existing = create_datetime_span(
            $existing->attribute('start')->object,
            $existing->property('end')
        );
        if ($new->intersects($existing)) {
            return {start => ['conflicting existent reservation']};
        }
    }
    return;
}

=head4 create_datetime_span($start, $end)

=cut

sub create_datetime_span {
    my ($start, $end) = @_;

    my ($end_h, $end_m) = split /:/, $end;
    return DateTime::Span->from_datetimes(
        start => $start,
        end   => $start->clone->set_hour($end_h)->set_minute($end_m)->subtract(seconds => 1)
    );
}

=head2 cancel

Cancel the given reservation.

=cut

sub cancel : CiderCMS('cancel') Args(1) {
    my ($self, $c, $id) = @_;

    my $context = $c->stash->{context};
    my $reservation = $c->model('DB')->get_object($c, $id, $context->{level} + 1);
    if ($reservation->{parent} == $context->{id}) {
        $reservation->set_property(cancelled_by => $c->user->get('name'));
        $reservation->update;
    }

    return $c->res->redirect($c->stash->{context}->uri . '/reserve');
}

1;
