package Hash::Ordered::Extension;

use strict;
use warnings;
use List::AllUtils;

{
package Hash::Ordered;

use constant ERROR_KEY_LENGTH_MISMATCH => "incorrect number of keys";

sub RenameKeys {
	my ($self, @names) = @_;
	die ERROR_KEY_LENGTH_MISMATCH if @names != $self->keys;
	my @values = $self->values;
	my @new_kv = List::AllUtils::mesh( @names, @values );
	$self->clear;
	$self->push(@new_kv);
}


}

1;
