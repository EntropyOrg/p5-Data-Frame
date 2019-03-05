package PDL::Role::Enumerable;

use strict;
use warnings;

use failures qw/levels::number/;

use Role::Tiny;
use Safe::Isa;
use List::AllUtils ();

with qw(PDL::Role::Stringifiable);

requires 'levels';

sub element_stringify_max_width {
	my ($self, $element) = @_;
	my @where_levels = @{ $self->{PDL}->uniq->unpdl };
	my @which_levels = @{ $self->levels }[@where_levels];
	my @lengths = map { length $_ } @which_levels;
	List::AllUtils::max( @lengths );
}

sub element_stringify {
	my ($self, $element) = @_;
	$self->levels->[ $element ];
}

sub number_of_levels {
	my ($self) = @_;
    return scalar( @{ $self->levels } );
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
	# TODO levels needs to be copied
	$ret->levels( $self->levels );
	$ret;
};

1;
