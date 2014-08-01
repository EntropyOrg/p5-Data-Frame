package Data::Frame;

use strict;
use warnings;

use Tie::IxHash;
use PDL;

use Moo;

has _columns => ( is => 'ro', default => sub { Tie::IxHash->new; } );

has _row_names => ( is => 'rw', default => sub { [] } );

sub number_of_columns {
	my ($self) = @_;
	$self->_columns->Length;
}

sub number_of_rows {
	...
}

# get
sub column_names {
	my ($self) = @_;
	# TODO wantarray
	[ $self->_columns->Keys ];
}

sub row_names {
	...
}

sub column {
	...
}

1;
