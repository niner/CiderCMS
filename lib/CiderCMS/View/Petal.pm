package CiderCMS::View::Petal;

use strict;
use base 'Catalyst::View::Petal';

use Petal::Utils qw( :default :hash );

=head1 NAME

CiderCMS::View::Petal - Petal View Component

=head1 SYNOPSIS

Catalyst View.

=head1 DESCRIPTION

Very nice component.

=head1 METHODS

=head2 process

=cut

sub process {
    my ($self, $c) = @_;

    my $root = $c->config->{root};

    my $base_dir = ["$root/templates", $root];
    unshift @$base_dir, "$root/ajax" if ($c->req->param('layout') or '') eq 'ajax';
    $self->config(
        base_dir => $base_dir,
    );

    $c->stash({
        uri_root    => $c->uri_for('/'),
        uri_static  => $c->uri_for('/static'),
    });

    $c->res->content_type('text/xml') if ($c->req->param('layout') or '') eq 'ajax';

    $self->SUPER::process($c);
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
