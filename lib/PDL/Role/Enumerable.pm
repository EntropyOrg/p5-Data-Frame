package PDL::Role::Enumerable;

use strict;
use warnings;

use Tie::IxHash;
use Tie::IxHash::Extension;
use Moo::Role;
use Try::Tiny;

with qw(PDL::Role::Stringifiable);

has _levels => ( is => 'ro', default => sub { Tie::IxHash->new; } );

sub element_stringify {
	my ($self, $element) = @_;
	( $self->_levels->Keys )[ $element ];
}

sub number_of_levels {
	my ($self) = @_;
	$self->_levels->Length;
}

sub levels {
	my ($self, @levels) = @_;
	if( @levels ) {
		try {
			$self->_levels->RenameKeys( @levels );
		} catch {
			die "incorrect number of levels" if /@{[ Tie::IxHash::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_levels->Keys ];
}

1;
