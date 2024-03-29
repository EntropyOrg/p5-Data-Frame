package PDL::Role::Enumerable;

use 5.010;
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
 
    my $new = $class->new( $self->levels, levels => $self->levels );
    $new->{PDL} = $self->{PDL}->uniq;
    return $new;
}

around qw(slice dice) => sub {
    my $orig = shift;
    my $self = shift;
    my $class = ref($self);

    my $pdl = $self->{PDL}->$orig(@_);
    my $ret = bless( { PDL => $pdl }, $class );

    # TODO levels needs to be copied
    $ret->levels( $self->levels );
    return $ret;
};

1;
