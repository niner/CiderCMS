package CiderCMS::Controller::System::Publish;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Temp;
use File::Find;
use Cwd;
use English qw( -no_match_vars );

=head1 NAME

CiderCMS::Controller::System::Publish - Catalyst Controller

=head1 DESCRIPTION

Controller handling the publishing of a static version of the website to a URI (e.g. FTP upload).

=head1 METHODS

=cut


=head2 publish

Publish a static version of the website to a URI.

=cut

sub publish : PathPart('system/publish') Chained('/system/init') {
    my ( $self, $c ) = @_;

    my $dir = File::Temp->newdir;
    my $cwd = cwd;

    chdir $dir;

    system '/usr/bin/wget', '-nv', '-r', '-k', $c->uri_for_instance('');
    find( sub {
        if (/\.html$/xm) {
            local ($INPLACE_EDIT, @ARGV) = ('', $_); # process file in place
            s!action="index\.html"!action="http://$File::Find::name"!gxm;
        }
    }, '.');

    chdir $c->req->uri->host;

    system '/usr/bin/lftp', '-c', 'mirror -R -v . ' . $c->model('DB')->get_object($c, 1)->property('publish_uri');

    chdir $cwd;

    return $c->res->body('Site published successfully');
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
