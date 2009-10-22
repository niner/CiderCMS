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
        management         => 1,
    });

    return 1;
}


=head2 manage

Shows a management interface for the current node.

=cut

sub manage : Regex('/manage\z') {
    my ( $self, $c ) = @_;

    my %params = %{ $c->req->params };
    my $save = delete $params{save};
    my $context = $c->stash->{context};

    if ($save) {
        $context->update({data => \%params});
        # return to the parent for page_elements and stay at the element for pages.
        return $c->res->redirect(($context->type->{page_element} ? $context->parent : $context)->uri_management());
    }

    $c->stash({ # values used by edit_form()
        uri_add     => $context->uri . '/manage_add',
        uri_delete  => $context->uri . '/manage_delete',
    });

    $c->stash({
        template => 'manage.zpt',
        content  => $c->stash->{context}->edit_form(),
    });

    return;
}

=head2 manage_add

Adds a new object as child of the current node.

=cut

sub manage_add : Regex('/manage_add\z') {
    my ( $self, $c ) = @_;

    my %params = %{ $c->req->params };
    my $type        = delete $params{type};
    my $parent_attr = delete $params{parent_attr};
    my $save        = delete $params{save};
    my $after       = delete $params{after};
    my $context = $c->stash->{context};

    my $object = CiderCMS::Object->new({c => $c, type => $type, parent => $context->{id}, parent_attr => $parent_attr, level => $context->{level}, data => \%params});

    if ($save) {
        $object->insert({after => $after});
        return $c->res->redirect(($object->type->{page_element} ? $context : $object)->uri_management());
    }

    my $uri = $c->req->uri;
    $uri->query('');

    $c->stash({
        type        => $type,
        after       => $after,
        parent_attr => $parent_attr,
        uri_action  => $uri,
    });

    $c->stash({
        template => 'manage.zpt',
        content  => $object->edit_form($uri),
    });

    return;
}

=head2 manage_delete

Deletes a child of the current node.

=cut

sub manage_delete : Regex('/manage_delete\z') {
    my ( $self, $c ) = @_;

    my $id = $c->req->param('id');

    my $object = $c->model('DB')->get_object($c, $id);

    $object->delete;

    return $c->res->redirect($c->stash->{context}->uri_management());
}

=head2 manage_paste

Cut and past an object to a new location.

=cut

sub manage_paste : Regex('/manage_paste\z') {
    my ( $self, $c ) = @_;

    my $object = $c->model('DB')->get_object($c, $c->req->param('id'));

    $object->move_to(parent => $c->stash->{context}, parent_attr => scalar $c->req->param('attribute'), after => scalar $c->req->param('after'));

    return $c->res->redirect($c->stash->{context}->uri_management());
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
