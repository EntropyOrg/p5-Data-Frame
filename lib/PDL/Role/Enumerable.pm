package PDL::Role::Enumerable;

use strict;
use warnings;

use failures qw/levels::number/;

use Tie::IxHash;
use Tie::IxHash::Extension;
use Role::Tiny;
use Try::Tiny;
use Safe::Isa;
use List::AllUtils ();

with qw(PDL::Role::Stringifiable);

requires '_levels';

sub element_stringify_max_width {
	my ($self, $element) = @_;
	my @where_levels = @{ $self->{PDL}->uniq->unpdl };
	my @which_levels = @{ $self->levels }[@where_levels];
	my @lengths = map { length $_ } @which_levels;
	List::AllUtils::max( @lengths );
}

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
			failure::levels::number->throw({
					msg => "incorrect number of levels",
					trace => failure->croak_trace,
				}
			) if $_->$_isa('failure::keys::number');
		};
	}
	[ $self->_levels->Keys ];
}

sub uniq {
    my $self  = shift;
    my $class = ref($self);
 
    my $uniq = $self->{PDL}->uniq;
    return $class->new(integer => $uniq, levels => $self->levels);
}

around qw(slice dice) => sub {
	my $orig = shift;
	my ($self) = @_;
	my $ret = $orig->(@_);
	# TODO _levels needs to be copied
	$ret->_levels( $self->_levels );
	$ret;
};

1;
