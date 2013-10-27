package CiderCMS::Attribute::Email;

use strict;
use warnings;

use base qw(CiderCMS::Attribute::String);

use Regexp::Common qw(Email::Address);

=head1 NAME

CiderCMS::Attribute::Email - Email attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Simple attribute for Email addresses

=head1 METHODs

=head2 validate

Check if email address looks valid.

=cut

sub validate {
    my ($self, $data) = @_;

    my $email = $data->{ $self->id };
    return 'missing' if $self->{mandatory} and not $email;
    return 'invalid' if $email and $email !~ /\A($RE{Email}{Address})\z/;
    return;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
