package Catalyst::DispatchType::CiderCMS;

use Moose;
extends 'Catalyst::DispatchType';

has _paths => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} },
);

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

sub register_custom {
    my ($self, $c, $custom, $action) = @_;

    $self->_paths->{$custom} = $action;
}

sub match {
    my ( $self, $c, $path ) = @_;

    return if @{ $c->req->args };
    $path =~ s!/+!/!gxm;
    my @path = split m!/!xm, $path;

    my $instance = shift @path;
    $c->stash->{instance} = $instance;

    my $filename = pop @path // ''; # empty path means / -> use index action
    unless (exists $self->_paths->{$filename}) {
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

__PACKAGE__->meta->make_immutable;

1;
