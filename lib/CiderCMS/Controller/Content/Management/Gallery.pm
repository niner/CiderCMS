package CiderCMS::Controller::Content::Management::Gallery;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Copy qw(move);
use File::Path qw(mkpath);
use File::Basename;

=head1 NAME

CiderCMS::Controller::Content::Management::Gallery - Catalyst Controller

=head1 DESCRIPTION

Management methods for image galleries.

=head1 METHODS

=head2 import

Bulk import images into the gallery.

=cut

sub import : Regex('/import\z') {
    my ( $self, $c ) = @_;

    my $context = $c->stash->{context};

    my $after;
    foreach (glob $c->fs_path_for_instance . '/../import/*') {
        my $image = CiderCMS::Object->new({c => $c, type => 'gallery_image', parent => $context->{id}, parent_attr => 'images', level => $context->{level} + 1, data => {image => basename($_)}});
        $image->insert({after => $after});

        my $path = $image->attribute('image')->fs_path;
        mkpath($path);
        move($_, $path);

        $after = $image;
    }

    return $c->res->redirect($context->uri_management);
}

=head2 manage_actions

=cut

CiderCMS->register_management_action(__PACKAGE__, sub {
        my ($self, $c) = @_;

        return {title => 'Import images', uri => $c->stash->{context}->uri . '/import'} if $c->stash->{context}{type} eq 'gallery';

        return;
    });

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
