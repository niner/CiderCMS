package CiderCMS::Attribute::Image;

use strict;
use warnings;

use File::Path qw(mkpath rmtree);

use base qw(CiderCMS::Attribute);

=head1 NAME

CiderCMS::Attribute::Image - Image attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Image attribute

=head1 METHODs

=head2 new({c => $c, object => $object, id => 'attr1', data => 'foo'})

=cut

sub new {
    my ($self, $params) = @_;

    $self = $self->SUPER::new($params);
    $self->set_data($self->{data});

    return $self;
}

=head2 data()

Returns an URI for this image

=cut

sub data {
    my ($self) = @_;

    return $self->{object}->uri_static . "/$self->{id}/$self->{data}";
}

=head2 set_data($data)

Upload a new file

=cut

sub set_data {
    my ($self, $filename) = @_;

    if (my $upload = $self->{c}->req->upload($self->{id})) {
        $filename = $upload->basename;

        if ($self->{object}{id}) {
            my $path = $self->fs_path;

            rmtree($path);
            mkpath($path);

            $upload->copy_to("$path/$self->{data}");
        }
    }

    return $self->SUPER::set_data($filename);
}

=head2 fs_path()

}Returns the file system path to this attribute.

=cut

sub fs_path {
    my ($self) = @_;

    return $self->{object}->fs_path . "/$self->{id}";
}

=head2 db_type

=cut

sub db_type {
    return 'varchar';
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
