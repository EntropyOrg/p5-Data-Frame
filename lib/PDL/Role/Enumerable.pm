package PDL::Role::Enumerable;

use strict;
use warnings;

use Hash::Ordered;
use Hash::Ordered::Extension;
use Moo::Role;
use Try::Tiny;
use List::AllUtils ();

with qw(PDL::Role::Stringifiable);

has _levels => ( is => 'rw', default => sub { Hash::Ordered->new; } );

sub element_stringify_max_width {
	my ($self, $element) = @_;
	my @where_levels = @{ $self->{PDL}->uniq->unpdl };
	my @which_levels = @{ $self->levels }[@where_levels];
	my @lengths = map { length $_ } @which_levels;
	List::AllUtils::max( @lengths );
}

sub element_stringify {
	my ($self, $element) = @_;
	( $self->_levels->keys )[ $element ];
}

sub number_of_levels {
	my ($self) = @_;
	scalar $self->_levels->keys;
}

sub levels {
	my ($self, @levels) = @_;
	if( @levels ) {
		try {
			$self->_levels->RenameKeys( @levels );
		} catch {
			die "incorrect number of levels" if /@{[ Hash::Ordered::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_levels->keys ];
}

around qw(slice uniq dice) => sub {
	my $orig = shift;
	my ($self) = @_;
	my $ret = $orig->(@_);
	# TODO _levels needs to be copied
	$ret->_levels( $self->_levels );
	$ret;
};

1;
