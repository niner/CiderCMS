package CiderCMS::Attribute::Recipient;

use strict;
use warnings;

use base qw(CiderCMS::Attribute);

use MIME::Lite;

=head1 NAME

CiderCMS::Attribute::Recipient - Recipient attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Recipient attribute. This attribute can send a posted form as email to a recipient.

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'varchar';
}

=head2 data

If called from within the management interface, it just returns the data.
If called from the website, it checks for a parameter named "send" and if present, sends an email containing the form data to the given recipient.
The email uses the parent object's "subject" or alternatively "title" attributes as subject. If both are unavailable it's just "Submitted form".

=cut

sub data {
    my ($self) = @_;

    my $params = $self->{c}->req->params;
    if (delete $params->{send}) {
        my $mail = MIME::Lite->new(
            From    => 'nine@detonation.org',
            To      => $self->{data},
            Subject => ($self->{object}->property('subject') or $self->{object}->property('title') or 'Submitted form'),
            Data    => (join "\n", map "$_: $params->{$_}", sort keys %$params),
        );

        $mail->send;
    }

    return $self->{c}->stash->{management} ? $self->{data} : '',
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
