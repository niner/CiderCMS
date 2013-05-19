package CiderCMS;

use strict;
use warnings;

use Catalyst::Runtime 5.80;
use Catalyst::DispatchType::CiderCMS;

# Set flags and add plugins for the application
#
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                Unicode::Encoding
                ConfigLoader
                Static::Simple

                FormValidator
                Authentication
                Session
                Session::State::Cookie
                Session::Store::FastMmap
                /;
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in cidercms.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name     => 'CiderCMS',
    encoding => 'UTF-8',
);

# Start the application
__PACKAGE__->setup();

=head1 NAME

CiderCMS - Catalyst based application

=head1 SYNOPSIS

    script/cidercms_server.pl

=head1 DESCRIPTION

CiderCMS is a very flexible CMS.

=head1 METHODS

=head2 prepare_path

Checks for an CIDERCMS_INSTANCE environment variable and prepends it to the path if present.

=cut

sub prepare_path {
    my ($self, @args) = @_;

    $self->maybe::next::method(@args);

    my $uri_raw = $self->request->uri->clone;
    if (my $instance = $ENV{CIDERCMS_INSTANCE}) {
        my $uri = $uri_raw->clone;

        my $path = $instance . $uri->path;

        $uri->path($path);
        $self->request->path($path);

        $uri->path_query('');
        $uri->fragment(undef);
        $self->stash({
            uri_instance => $uri,
            uri_static   => "$uri/static",
            uri_raw      => $uri_raw,
        });
    }
    else {
        $self->stash->{uri_raw} = $uri_raw;
    }

    return;
}

if ($ENV{CIDERCMS_INSTANCE}) {
    __PACKAGE__->config->{static}{include_path} = [
        __PACKAGE__->config->{root} . '/instances/',
        __PACKAGE__->config->{root},
    ];
}

=head2 uri_for_instance(@path)

Creates an URI relative to the current instance's root

=cut

sub uri_for_instance {
    my ($self, @path) = @_;

    return ($self->stash->{uri_instance} ||= $self->uri_for('/') . $self->stash->{instance}) . (@path ? join '/', '', @path : '');
}

=head2 uri_static_for_instance()

Returns an URI for static files for this instance

=cut

sub uri_static_for_instance {
    my ($self, @path) = @_;

    return join '/', ($self->stash->{uri_static} or $self->uri_for('/') . (join '/', 'instances', $self->stash->{instance}, 'static')), @path;
}

=head2 fs_path_for_instance()

Returns a file system path for the current instance's root

=cut

sub fs_path_for_instance {
    my ($self) = @_;

    return $self->config->{root} . '/instances/' . $self->stash->{instance} . '/static';
}

=head2 register_management_action

Controllers may register subroutines returning additional actions for the management interface dynamically.
For example:

    CiderCMS->register_management_action(__PACKAGE__, sub {
            my ($self, $c) = @_;
            return {title => 'Foo', uri => $c->uri_for('foo')}, { ... };
        });

=cut

my %management_actions;

sub register_management_action {
    my ($self, $package, $action_creator) = @_;

    $management_actions{$package} = $action_creator;

    return;
}

=head2 management_actions

Returns the registered management actions

=cut

sub management_actions {
    my ($self) = @_;
    
    return \%management_actions;
}

=head1 SEE ALSO

L<CiderCMS::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
