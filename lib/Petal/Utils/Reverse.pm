package Petal::Utils::Reverse;

use strict;
use warnings::register;

use Carp;

use base qw( Petal::Utils::Base );

use constant name    => 'reverse';
use constant aliases => qw();

our $VERSION  = ((require Petal::Utils), $Petal::Utils::VERSION)[1];
our $REVISION = 1;

sub process {
    my $class = shift;
    my $hash  = shift;
    my $args  = shift || confess( "'reverse' expects 1 variable (got nothing)!" );

    my @args = $class->split_args( $args );
    my $key = $args[0] || confess( "1st arg to 'reverse' should be an array (got nothing)!" );

    my $arrayref = $hash->fetch($key);
    return [reverse @$arrayref];
}

1;

__END__

Description: Reverse elements returned from an array

Basic Usage:
  reverse:<list>
    list - a list

Example:
    <div class="content" tal:repeat="fact reverse:facts">
      <p tal:content="fact/fld_fact">Fact</p>
    </div>
