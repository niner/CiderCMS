package CiderCMS::User;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Authentication::User';

use List::MoreUtils 'all';
use Try::Tiny;
use Scalar::Util qw(blessed);

has 'config'    => (is => 'rw');
has '_user'     => (is => 'rw');
has '_roles'    => (is => 'rw');

sub new {
    my ( $class, $config, $c) = @_;

    my $self = {
        config => $config,
        _roles => undef,
        _user => undef
    };

    bless $self, $class;

    return $self;
}


sub load {
    my ($self, $authinfo, $c) = @_;

    Catalyst::Exception->throw(
        "parent field not present in authentication data. Missing in your login form?"
    ) unless $authinfo->{parent};
    Catalyst::Exception->throw(
        "parent_attr field not present in authentication data. Missing in your login form?"
    ) unless $authinfo->{parent_attr};

    my $parent = $c->model('DB')->get_object($c, delete $authinfo->{parent});
    Catalyst::Exception->throw(
        "Object $authinfo->{parent} not found. Check the parent field in your login form."
    ) unless $parent;

    my $attribute = $parent->attribute(delete $authinfo->{parent_attr});

    Catalyst::Exception->throw(
        "Object $authinfo->{parent} has no attribute $authinfo->{parent_attr}"
    ) unless $attribute;
    Catalyst::Exception->throw("Attribute $attribute cannot contain user objects")
        unless $attribute->can('filtered');

    $authinfo->{$_} or delete $authinfo->{$_} foreach keys %$authinfo;
    my @users = $attribute->filtered(%$authinfo);

    return undef unless @users == 1;
    my $user = $users[0];

    Catalyst::Exception->throw("User has no password attribute")
        unless $user->attribute('password');

    $self->_user($user);

    return $self->get_object ? $self : undef;
}

sub supported_features {
    my $self = shift;

    return {
        session => 1,
    };
}


sub roles {
    my ( $self ) = shift;

    Catalyst::Exception->throw("user->roles accessed, but roles not supported yet");
}

sub for_session {
    my $self = shift;

    return $self->_user->{id};
}

sub from_session {
    my ($self, $frozenuser, $c) = @_;

    $self->_user($c->model('DB')->get_object($c, $frozenuser));
    return $self->_user ? $self : undef;
}

sub get {
    my ($self, $field) = @_;

    return $self->_user->property($field);
}

sub get_object {
    my ($self, $force) = @_;

    return $self->_user;
}

sub obj {
    my ($self, $force) = @_;

    return $self->get_object($force);
}

sub can {
    my $self = shift;
    return $self->SUPER::can(@_) || do {
        my ($method) = @_;
        if (my $code = $self->_user->can($method)) {
            sub { shift->_user->$code(@_) }
        }
        else {
            undef;
        }
    };
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    if (my $code = $self->_user->can($method)) {
        return $self->_user->$code(@_);
    }
    else {
        # XXX this should also throw
        return undef;
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
__END__

=head1 NAME

CiderCMS::User - The backing user
class for the Catalyst::Authentication::Store::CiderCMS storage
module.

=head1 SYNOPSIS

Internal - not used directly, please see
L<Catalyst::Authentication::Store::CiderCMS> for details on how to
use this module. If you need more information than is present there, read the
source.



=head1 DESCRIPTION

The CiderCMS::User class implements user storage
connected to an underlying CiderCMS instance.

=head1 SUBROUTINES / METHODS

=head2 new

Constructor.

=head2 load ( $authinfo, $c )

Retrieves a user from storage using the information provided in $authinfo.

=head2 supported_features

Indicates the features supported by this class.  This is currently just Session.

=head2 roles

Not yet supported.

=head2 for_session

Returns a serialized user for storage in the session.

=head2 from_session

Revives a serialized user from storage in the session.

=head2 get ( $fieldname )

Returns the value of $fieldname for the user in question.

=head2 get_object

Retrieves the CiderCMS::Object that corresponds to this user

=head2 obj (method)

Synonym for get_object

=head2 AUTOLOAD

Delegates method calls to the underlieing user object.

=head2 can

Delegates handling of the C<< can >> method to the underlieing user object.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Jason Kuri (jayk@cpan.org)
Stefan Seifert (nine@detonation.org)

=head1 CONTRIBUTORS

Matt S Trout (mst) <mst@shadowcat.co.uk>

(fixes wrt can/AUTOLOAD sponsored by L<http://reask.com/>)

=head1 LICENSE

Copyright (c) 2007-2010 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
