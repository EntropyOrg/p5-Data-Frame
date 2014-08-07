package PDL::Role::Enumerable;

use strict;
use warnings;

use Tie::IxHash;
use Moo::Role;

has _levels => ( is => 'ro', default => sub { Tie::IxHash->new; } );

sub levels {
	my ($self) = @_;
	$self->_levels->Keys;
}

1;
