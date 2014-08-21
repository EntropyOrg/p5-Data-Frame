package PDL::Role::Stringifiable;

use strict;
use warnings;
use Moo::Role;

has element_stringify => ( is => 'rw', default => sub {
	sub {
		my($self, $element) = @_;
		"$element";
	}
});

sub string {
	# TODO
  my ($self) = @_;
  if( $self->ndims == 1 ) {
    return $self->string1d;
  }
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


1;
