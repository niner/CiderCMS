package CiderCMS::Controller::Custom::Registration;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller';

use Email::Sender::Simple;
use Email::Stuffer;
use Encode qw(encode);
use Hash::Merge qw(merge);

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
    unless ($errors) {
        $errors = merge(
            $self->check_email_whitelist($c, $params),
            $self->check_duplicates($c, $params),
        );
    }
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
                . "\n\n" . $c->config->{registration_rules}
            )
            ->send;

        return $c->res->redirect($c->stash->{context}->property('success')->[0]->uri_index);
    }

    return;
}

sub check_email_whitelist {
    my ($self, $c, $params) = @_;

    my $whitelist = $c->config->{registration_email_whitelist}
        or return;

    my %whitelist = map { $_ => 1 } @$whitelist;

    return if $whitelist{$params->{email}};

    return { email => ['Emailadresse nicht in der Mitgliederliste'] };
}

sub check_duplicates {
    my ($self, $c, $params) = @_;

    my $username = $params->{username};
    my $context  = $c->stash->{context};

    my $unverified = $context->attribute('children')->filtered(username => $username);
    my $registered = $self->list($c)->attribute('children')->filtered(username => $username);

    return { username => ['bereits vergeben'] } if @$unverified or @$registered;
}

sub verify : CiderCMS('verify_registration') {
    my ( $self, $c ) = @_;

    my $users = $c->stash->{context}->attribute('children')->filtered(
        email => $c->req->params->{email}
    );
    die "No user found for " . $c->req->params->{email} unless @$users;

    my $user = $users->[0];
    $user->move_to(parent => $self->list($c), parent_attr => 'children');

    return $c->res->redirect($c->stash->{context}->property('verified')->[0]->uri_index);
}

sub list {
    my ($self, $c) = @_;

    return $c->stash->{context}->object_by_id($c->stash->{context}->property('list'));
}

1;
