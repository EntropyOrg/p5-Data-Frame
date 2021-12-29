package PDL::Role::Stringifiable;

use strict;
use warnings;
use Role::Tiny;

requires 'element_stringify';
requires 'element_stringify_max_width';

sub element_stringify {
		my($self, $element) = @_;
		"$element";
}

sub string {
	# TODO
	my ($self) = @_;

    if ($self->nelem > $PDL::toolongtoprint) {
        return "TOO LONG TO PRINT";
    }

    my $ndims = $self->ndims;
	if( $ndims == 0 ) {
		return $self->element_stringify( $self->at() );
	}
	elsif( $ndims == 1 ) {
		return $self->string1d;
	}
	# TODO string2d, stringNd
	...
}

sub string1d {
	my ($self) = @_;
	my $str = "[";

	for my $w (0..$self->nelem-1) {
		$str .= " ";
		$str .= $self->element_stringify( $self->at($w) );
	}
	$str .= " " if ($self->nelem > 0);
	$str .= "]";
	$str;
}

sub string2d {
	...
}


1;
