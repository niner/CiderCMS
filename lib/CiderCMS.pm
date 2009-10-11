package CiderCMS;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                Unicode
                ConfigLoader
                Static::Simple

                FormValidator
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

__PACKAGE__->config( name => 'CiderCMS' );

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
    my ($self) = @_;

    $self->maybe::next::method(@_);

    if (my $instance = $ENV{CIDERCMS_INSTANCE}) {
        my $uri = $self->request->uri->clone;

        my $path = $instance . $uri->path;

        $uri->path($path);
        $self->request->path($path);

        $uri->path_query('');
        $uri->fragment(undef);
        $self->stash({
            uri_instance => $uri,
            uri_static   => "$uri/static",
        });
    }
}

=head2 uri_for_instance(@path)

Creates an URI relative to the current instance's root

=cut

sub uri_for_instance {
    my ($self, @path) = @_;

    return ($self->stash->{uri_instance} ||= $self->uri_for('/') . $self->stash->{instance}) . (@path ? join '/', '', @path : '');
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
