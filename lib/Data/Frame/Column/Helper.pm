package Data::Frame::Column::Helper;

use strict;
use warnings;

use Moo;

has df => ( is => 'rw' ); # isa Data::Frame

use overload '&{}' => sub ($$) {
	my $self = shift;
	sub { $self->df->column(@_); };
};


1;
