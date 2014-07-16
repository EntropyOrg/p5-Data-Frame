package PDL::Factor;

use strict;
use warnings;
use parent qw(PDL);

use Moo;
use MooX::InsideOut;
use Tie::IxHash;

extends 'PDL';

has _levels => ( is => 'ro', default => sub { Tie::IxHash->new; } );

sub _add_level {

}

sub BUILD {

}


1;
