package Catalyst::Authentication::Store::CiderCMS;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

use CiderCMS::User;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config/);
}

sub new {
    my ( $class, $config, $app ) = @_;

    my $self = {
        config => $config
    };

    bless $self, $class;

}

sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

    my $user = CiderCMS::User->new($self->{'config'}, $c);
    return $user->from_session($frozenuser, $c);
}

sub for_session {
    my ($self, $c, $user) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $user = CiderCMS::User->new($self->{'config'}, $c);

    return $user->load($authinfo, $c);

}

sub user_supports {
    my $self = shift;
    # this can work as a class method on the user class
    CiderCMS::User->supports( @_ );
}

__PACKAGE__;

__END__

=head1 NAME

Catalyst::Authentication::Store::CiderCMS - A storage class for Catalyst Authentication

=head1 SYNOPSIS

    use Catalyst qw/
                    Authentication
                 /;

    __PACKAGE__->config('Plugin::Authentication' => {
        default_realm => 'members',
        realms => {
            members => {
                credential => {
                    class => 'Password',
                    password_field => 'password',
                    password_type => 'clear'
                },
                store => {
                    class => 'CiderCMS',
                }
            }
        }
    });

    # Log a user in:

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate({
            username => $ctx->req->params->{username},
            password => $ctx->req->params->{password},
        })
    }

=head1 DESCRIPTION

The Catalyst::Authentication::Store::CiderCMS class provides
access to authentication information stored in the instances database.

=head1 USAGE

The L<Catalyst::Authentication::Store::CiderCMS> storage module
is not called directly from application code.  You interface with it
through the $ctx->authenticate() call.

=head1 METHODS

There are no publicly exported routines in the CiderCMS authentication
store (or indeed in most authentication stores). However, below is a
description of the routines required by L<Catalyst::Plugin::Authentication>
for all authentication stores.  Please see the documentation for
L<Catalyst::Plugin::Authentication::Internals> for more information.


=head2 new ( $config, $app )

Constructs a new store object.

=head2 find_user ( $authinfo, $c )

Finds a user using the information provided in the $authinfo hashref and
returns the user, or undef on failure. This is usually called from the
Credential. This translates directly to a call to
L<CiderCMS::User>'s load() method.

=head2 for_session ( $c, $user )

Prepares a user to be stored in the session. Currently returns the value of
the user's id field (as indicated by the 'id_field' config element)

=head2 from_session ( $c, $frozenuser)

Revives a user from the session based on the info provided in $frozenuser.
Currently treats $frozenuser as an id and retrieves a user with a matching id.

=head2 user_supports

Provides information about what the user object supports.

=head2 auto_update_user( $authinfo, $c, $res )

This method is called if the realm's auto_update_user setting is true. It
will delegate to the user object's C<auto_update> method.

=head2 auto_create_user( $authinfo, $c )

This method is called if the realm's auto_create_user setting is true. It
will delegate to the user class's (resultset) C<auto_create> method.

=head1 NOTES

As of the current release, session storage consists of simply storing the user's
id in the session, and then using that same id to re-retrieve the user's information
from the database upon restoration from the session.  More dynamic storage of
user information in the session is intended for a future release.

=head1 BUGS AND LIMITATIONS

None known currently; please email the author if you find any.

=head1 SEE ALSO

L<CiderCMS>, L<Catalyst::Plugin::Authentication> and L<Catalyst::Plugin::Authentication::Internals>

=head1 AUTHOR

Jason Kuri (jayk@cpan.org)
Stefan Seifert (nine@detonation.org)

=head1 LICENSE

Copyright (c) 2007 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
