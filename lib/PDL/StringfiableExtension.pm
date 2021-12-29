package PDL::StringfiableExtension;

use strict;
use warnings;
use PDL::Lite ();
use List::AllUtils ();


{
	# This is a hack.
	# This gets PDL to stringify the single element and then gets the
	# element out of that string.
	my $_pdl_stringify_temp = PDL::Core::pdl([[0]]);
	my $_pdl_stringify_temp_single = PDL::Core::pdl(0);
	sub PDL::element_stringify {
		my ($self, $element) = @_;
		if( $self->ndims == 0 ) {
			return $_pdl_stringify_temp_single->set(0, $element)->string;
		}
		# otherwise
		my $string = $_pdl_stringify_temp->set(0,0, $element)->string;
		( $_pdl_stringify_temp->string =~ /\[(.*)\]/ )[0];
	}
}

sub PDL::element_stringify_max_width {
	my ($self) = @_;
	my @vals = @{ $self->uniq->unpdl };
	my @lens = map { length $self->element_stringify($_) } @vals;
	List::AllUtils::max( @lens );
}

1;
