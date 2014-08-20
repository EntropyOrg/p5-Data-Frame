package PDL::Role::Stringifiable;

use strict;
use warnings;
use Moo;

has element_stringify => ( is => 'rw', default => sub {
	sub {
		my($self, $element) = @_;
		"$element";
	}
});

sub string {
	# TODO
}

1;
