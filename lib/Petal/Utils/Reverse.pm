package Petal::Utils::Reverse;

use strict;
use warnings::register;

=head1 NAME

Petal::Utils::Reverse - Petal modifier for reversing lists

=head1 DESCRIPTION

Reverse elements returned from an array.

=head1 SYNOPSIS

Basic Usage:
  reverse:<list>
    list - a list

Example:
    <div class="content" tal:repeat="fact reverse:facts">
      <p tal:content="fact/fld_fact">Fact</p>
    </div>

=cut

use Carp;

use base qw( Petal::Utils::Base );

=head1 constants

=head2 name
=head2 aliases

=cut

use constant name    => 'reverse';
use constant aliases => qw();

our $VERSION  = ((require Petal::Utils), $Petal::Utils::VERSION)[1];
our $REVISION = 1;

=head1 METHODS

=head2 process

Check user access to the context node.

=cut

sub process {
    my $class = shift;
    my $hash  = shift;
    my $args  = shift || confess( "'reverse' expects 1 variable (got nothing)!" );

    my @args = $class->split_args( $args );
    my $key = $args[0] || confess( "1st arg to 'reverse' should be an array (got nothing)!" );

    my $arrayref = $hash->fetch($key);
    return [reverse @$arrayref];
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
