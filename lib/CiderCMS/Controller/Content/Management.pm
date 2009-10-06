package CiderCMS::Controller::Content::Management;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CiderCMS::Controller::Content::Management - Catalyst Controller

=head1 DESCRIPTION

Controller for managing content.

=head1 METHODS

=head2 auto

Sets up context information according to the current path

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash({
        uri_manage_types   => $c->uri_for_instance('system/types'),
        uri_manage_content => $model->get_object($c, 1)->uri_management,
        uri_view           => $c->stash->{context}->uri_index,
    });
}


=head2 manage

=cut

sub manage : Regex('/manage\z') {
    my ( $self, $c ) = @_;

    $c->stash({ # values used by edit_form()
        uri_add  => $c->stash->{context}->uri . '/manage_add',
    });

    $c->stash({
        template => 'manage.zpt',
        content  => $c->stash->{context}->edit_form(),
    });
}

=head2 manage_add

=cut

sub manage_add : Regex('/manage_add\z') {
    my ( $self, $c ) = @_;

    my %params = %{ $c->req->params };
    my $type = delete $params{type};
    my $save = delete $params{save};

    my $object = CiderCMS::Object->new({c => $c, type => $type, parent => $c->stash->{context}->{id}, data => \%params});

    if ($save) {
        $object->insert();
        $c->res->redirect($c->stash->{context}->uri_management());
    }

    $c->stash({
        type     => $type,
    });

    $c->stash({
        template => 'manage.zpt',
        content  => $object->edit_form(),
    });
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
