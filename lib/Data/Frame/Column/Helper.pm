package Data::Frame::Column::Helper;

use strict;
use warnings;

use Moo;

has _df => ( is => 'rw' ); # isa Data::Frame

use overload '&{}' => sub ($$) {
	my $self = shift;
	sub { $self->_df->column(@_); };
};

sub AUTOLOAD {
	my $self = shift;
	(my $colname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	$self->_df->column($colname);
}

1;
