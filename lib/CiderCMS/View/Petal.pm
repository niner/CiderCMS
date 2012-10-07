package CiderCMS::View::Petal;

use strict;
use warnings;

use base 'Catalyst::View::Petal';

use Petal::Utils qw( :all );

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

    if (my $instance = $c->stash->{instance}) {
        $self->config(base_dir => ["$root/instances/$instance/templates", "$root/templates"]);
        $c->stash->{uri_static} ||= $c->uri_static_for_instance();
    }
    else {
        $self->config(base_dir => "$root/templates");
    }

    $c->stash({
        uri_root       => $c->uri_for('/'),
        uri_sys_static => $c->uri_for($ENV{CIDERCMS_INSTANCE} ? '/sys_static' : '/static'),
    });

    return $self->SUPER::process($c);
}

=head2 render_template

Renders a Petal template and returns the result as string.

=cut

sub render_template {
    my ($self, $c, $stash) = @_;

    my $root = $c->config->{root};
    my $instance = $c->stash->{instance};

    my $template = Petal->new(
        %{ $self->config },
        base_dir => ["$root/instances/$instance/templates", "$root/templates"],
        file => $stash->{template},
    );

    return $template->process({
        c              => $c,
        uri_static     => ($c->stash->{uri_static} or $c->uri_static_for_instance()),
        uri_sys_static => $c->uri_for($ENV{CIDERCMS_INSTANCE} ? '/sys_static' : '/static'),
        %$stash,
    });
}

__PACKAGE__->config(input => 'XHTML', output => 'XHTML');

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
