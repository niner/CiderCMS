package CiderCMS::Attribute::DateTime;

use strict;
use warnings;
use v5.14;

use DateTime;
use DateTime::Format::Flexible;
use DateTime::Format::ISO8601;

use base qw(CiderCMS::Attribute::Date CiderCMS::Attribute::Time);

=head1 NAME

CiderCMS::Attribute::DateTime - DateTime attribute

=head1 SYNOPSIS

See L<CiderCMS::Attribute>

=head1 DESCRIPTION

Composed date and time attribute

=head1 METHODs

=head2 db_type

=cut

sub db_type {
    return 'timestamp';
}

=head2 set_data_from_form($data)

Sets this attribute's data from submitted form data.

=cut

sub set_data_from_form {
    my ($self, $data) = @_;

    my $value = $data->{ $self->id . '_date' } . ' ' . $data->{ $self->id . '_time' };
    $value = $self->parse_datetime($value);

    return $self->set_data($value->iso8601);
}

=head2 validate

=cut

sub validate {
    my ($self, $data) = @_;

    my $date = $data->{ $self->id . '_date' };
    my $time = $data->{ $self->id . '_time' };
    my $value = $date ? $time ? "$date $time" : $date : undef;
    return 'missing' if $self->{mandatory} and not defined $value;

    my $parsed = eval {
        $self->parse_datetime($value);
    };
    return 'invalid' if $@;
    return;
}

sub parse_datetime {
    my ($self, $value) = @_;

    $value .= ':0' unless $value =~ /\d+:\d+:\d+/;
    return DateTime::Format::Flexible->parse_datetime($value, european => 1);
}

=head2 object

Returns a L<DateTime> object initialized with this attribute's data

=cut

sub object {
    my ($self) = @_;

    return DateTime::Format::ISO8601->parse_datetime($self->data =~ s/ /T/r);
}

=head2 filter_matches($value)

Returns true if this attribute matches the given filter value.
$value may be 'future' to check if this date lies in the future.

=cut

sub filter_matches {
    my ($self, $value) = @_;

    if ($value eq 'past') {
        return DateTime->now > $self->object;
    }

    if ($value eq 'future') {
        return DateTime->now < $self->object;
    }

    if ($value eq 'today') {
        return DateTime->now->ymd eq $self->object->ymd;
    }

    return;
}

=head2 is_today()

Returns true if the stored day is today.

=cut

sub is_today {
    my ($self, $value) = @_;

    return DateTime->now->ymd eq $self->object->ymd;
}

=head2 format($format)

Returns a representation of the stored time according to the given format.
See 'strftime Patterns' in L<DateTime> for details about the format.

=cut

sub format {
    my ($self, $format) = @_;

    return $self->object->strftime($format);
}

=head2 delegated methods

See L<DateTime> for a description of these methods.

=head3 ymd

=cut

sub ymd {
    my ($self) = @_;
    return $self->object->ymd;
}

=head3 time

=cut

sub time {
    my ($self) = @_;
    return $self->object->time;
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
