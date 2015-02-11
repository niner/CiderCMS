package CiderCMS::Attribute::Image;

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Image::Imlib2;

use base qw(CiderCMS::Attribute::File);

=head1 NAME

CiderCMS::Attribute::Image - Image attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Image attribute

=head1 METHODs

=head2 thumbnail($width, $height)

Returns the URL of a thumbnail conforming to the given size constraints.

=cut

sub thumbnail {
    my ($self, $width, $height) = @_;

    return unless $self->{data};

    my $path = $self->fs_path;
    my $thumb_name = $self->{data};
    $thumb_name =~ s/(\. \w+) \z/_${width}_${height}$1/xm;

    unless (-e "$path/$thumb_name") {
        my $image = eval { Image::Imlib2->load("$path/$self->{data}"); };
        warn $@ if $@;
        return '#nonexisting' unless $image;

        if ($width and $height) {
            (($image->width / $width > $image->height / $height) ? $height : $width) = 0;
        }

        my $thumb = $image->create_scaled_image($width, $height);
        $thumb->set_quality(90);
        $thumb->save("$path/$thumb_name");
    }

    return $self->{object}->uri_static . "/$self->{id}/$thumb_name";
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
