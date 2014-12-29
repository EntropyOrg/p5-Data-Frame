package Data::Frame::Column::Helper;

use strict;
use warnings;

use Moo;

has dataframe => ( is => 'rw' ); # isa Data::Frame

use overload '&{}' => sub ($$) {
	my $self = shift;
	sub { $self->dataframe->column(@_); };
};

sub AUTOLOAD {
	my $self = shift;
	(my $colname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	$self->dataframe->column($colname);
}

1;
