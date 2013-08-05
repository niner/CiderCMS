package CiderCMS::Search;

use strict;
use warnings;

use Hash::Merge qw(merge);
use Scalar::Util qw(weaken);
use List::MoreUtils qw(all);

=head1 NAME

CiderCMS::Search - Queries

=head1 SYNOPSIS

See L<CiderCMS>

=head1 DESCRIPTION

=head1 METHODS

=head2 new({c => $c, filters => $filters})

=cut

sub new {
    my ($class, $params) = @_;
    $class = ref $class if ref $class;

    my $self = bless $params, $class;

#    weaken($self->{c});

    return $self;
}

sub search {
    my ($self, $params) = @_;

    return $self->new(merge({ %$self }, $params));
}

sub sort {
    my ($self, @keys) = @_;

    return $self->new(merge({sort => \@keys}, { %$self }));
}

sub list {
    my ($self) = @_;

    my @objects =
        $self->{c}->model('DB')->object_children($self->{c}, $self->{parent}, $self->{parent_attr});

    my $filters = $self->{filters};

    if (exists $filters->{type}) {
        @objects = grep {$_->{type} eq $filters->{type}} @objects;
        delete $filters->{type};
    }

    @objects = grep {
        my $object = $_;
        all {
            $object->attribute($_)->filter_matches($filters->{$_})
        } keys %$filters,
    } @objects;

    if ($self->{sort}) {
        my @sort_keys = @{ $self->{sort} };
        @objects = sort {
            foreach (@sort_keys) {
                my $res = $a->property($_) cmp $b->property($_);
                return $res if $res;
            }
            return 0;
        } @objects;
    }

    return wantarray ? @objects : \@objects;
}

1;
