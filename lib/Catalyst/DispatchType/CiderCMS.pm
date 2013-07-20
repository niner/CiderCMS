package Catalyst::DispatchType::CiderCMS;

use Moose;
extends 'Catalyst::DispatchType';

=head1 NAME

Catalyst::DispatchType::CiderCMS - Catalyst DispatchType

=head1 DESCRIPTION

A custom DispatchType for supporting CiderCMS URIs. For example
http://localhost/test.example/foo/bar/index.html would forward to the
index_html action in Controller::Content. Checks if the given
instance exists and the 'foo' and 'bar' content nodes exist.

=cut

has _paths => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} },
);

=head1 METHODS

=head2 register

Register the action for all filenames given by CiderCMS attributes.

=cut

sub register {
    my ( $self, $c, $action ) = @_;
    my $attrs    = $action->attributes;
    my @register = @{ $attrs->{'CiderCMS'} || [] };

    foreach my $r (@register) {
        $self->register_custom( $c, $r, $action );
    }

    return 1 if @register;
    return 0;
}

=head2 register_custom

Registers an action for the given filename.

=cut

sub register_custom {
    my ($self, $c, $custom, $action) = @_;

    $self->_paths->{$custom} = $action;
}

=head2 match

Checks if the given path contains any registered filenames, if the first path
part corresponds to an existing instance and if the other path parts are valid
content nodes. If all checks are successful succeeds for the registered action.

=cut

sub match {
    my ( $self, $c, $path ) = @_;

    $path =~ s!/+!/!gxm;
    my @path = split m!/!xm, $path;

    my $instance = shift @path;
    $c->stash->{instance} = $instance;

    my $filename = pop @path // ''; # empty path means / -> use index action
    unless (
        exists $self->_paths->{$filename}
        and (
            not exists $self->_paths->{$filename}->attributes->{Args}
            or not defined $self->_paths->{$filename}->attributes->{Args}
            or $self->_paths->{$filename}->attributes->{Args}[0] == @{ $c->req->args }
        )
    ) {
        push @path, $filename;
        $filename = '';
    }

    my $model = $c->model('DB');
    return unless $model->initialize($c);

    unshift @path, '';
    my @objects = eval {
        $model->traverse_path($c, \@path);
    };
    $c->stash->{dispatch_error} = $@ if $@;
    return if $@ or not @objects;

    $c->stash({
        parents => \@objects,
        context => $objects[-1],
        site    => $objects[0],
    });

    my $action = $self->_paths->{$filename};
    $c->req->action($path);
    $c->req->match($path);
    $c->action($action);
    $c->namespace( $action->namespace );

    return 1;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
