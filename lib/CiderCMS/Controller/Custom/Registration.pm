package CiderCMS::Controller::Custom::Registration;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller';

use Email::Sender::Simple;
use Email::Stuffer;
use Encode qw(encode);

=head2 register

Register a new user.

=cut

sub register : CiderCMS('register') {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;
    my $object = $c->stash->{context}->new_child(
        attribute => 'children',
        type      => 'user',
    );

    my $errors = $object->validate($params);
    if ($errors) {
        $_ = join ', ', @$_ foreach values %$errors;
        $c->stash({
            %$params,
            errors => $errors,
        });
        $c->forward('/content/index_html');
    }
    else {
        $object->insert({data => $params});

        my $verify_uri = URI->new($c->stash->{context}->uri . '/verify_registration');
        $verify_uri->query_form({email => $params->{email}});

        Email::Stuffer->from('noreply@' . $c->stash->{instance})
            ->to($params->{email})
            ->subject('Bestätigung der Anmeldung zu ' . $c->stash->{instance})
            ->text_body(
                "Durch Klick auf folgenden Link bestätigen Sie die Anmeldung und, dass Sie
untenstehende Regeln akzeptieren:\n\n"
                . $verify_uri
                . <<RULES


Regeln

Eintragungen sind bis maximal 12 Stunden vor dem jeweiligen Termin möglich.

Minimum der Reservierungsdauer sind 30 Minuten.

Tank- und Pflegezeiten unmittelbar nach dem Flug sind in die Reservierung mit
einzurechnen.

Reservierungen, bei denen das Flugzeug über Nacht nicht im Heimathangar steht,
sind mit dem Linzer Vorstand abzustimmen.

Wenn das Flugzeug nicht innerhalb der ersten 15 Minuten des Reservierungs-
zeitraumes durch den Reservierenden in Anspruch genommen wird, verfällt die
Reservierung und das Flugzeug steht im betreffenden Zeitraum frei zur Verfügung.
Zeitliche Überziehungen (zu spätes Zurückkommen) gehen zu Lasten der nächsten
Reservierung (sollte unmittelbar eine anschließen).

Nicht „reservierte“ Flugzeiten können so wie bisher in Anspruch genommen werden.

Der Pilot muss sich vor Flugantritt davon überzeugen, dass für den von ihm
geplanten Zeitraum keine Reservierung vorliegt. Das Flugzeug muss aber
spätestens bei Beginn des nächsten Reservierungszeitraumes bereitstehen
(Tankzeiten unmittelbar nach dem Flug sind mit einzurechnen).

Reservierungen, die nicht in Anspruch genommen werden können, müssen vom
Reservierenden so lange als möglich im Vorhinein wieder storniert werden.
Steht ein Flugzeug aus z.B. Wartungsgründen nicht zur Verfügung, so ist dies
in der Reservierungsliste mit „UNKLAR“ gekennzeichnet. Bei bereits vorliegenden
Reservierungen werden die Betroffenen per Mail (Adresse bei der Registrierung
angegeben) verständigt.
RULES
            )
            ->send;

        return $c->res->redirect($c->stash->{context}->property('success')->[0]->uri_index);
    }

    return;
}

sub verify : CiderCMS('verify_registration') {
    my ( $self, $c ) = @_;

    my $users = $c->stash->{context}->attribute('children')->filtered(
        email => $c->req->params->{email}
    );
    die "No user found for " . $c->req->params->{email} unless @$users;

    my $user = $users->[0];
    $user->move_to(parent => $c->stash->{context}->parent, parent_attr => 'children');

    return $c->res->redirect($c->stash->{context}->property('verified')->[0]->uri_index);
}

1;

