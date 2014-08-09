package Tie::IxHash::Extension;

use strict;
use warnings;
use List::AllUtils;

{
package Tie::IxHash;

use constant ERROR_KEY_LENGTH_MISMATCH => "incorrect number of keys";

sub RenameKeys {
	my ($self, @names) = @_;
	die ERROR_KEY_LENGTH_MISMATCH if @names != $self->Length;
	my @values = $self->Values;
	my @new_kv = List::AllUtils::mesh( @names, @values );
	$self->Splice(0, $self->Length, @new_kv);
}


}

1;
