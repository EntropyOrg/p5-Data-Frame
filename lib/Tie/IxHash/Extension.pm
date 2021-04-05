package Tie::IxHash::Extension;

use strict;
use warnings;
use List::AllUtils;

{
package # hide from PAUSE
    Tie::IxHash;

use failures qw/keys::number/;

sub RenameKeys {
	my ($self, @names) = @_;
	failure::keys::number->throw if @names != $self->Length;
	my @values = $self->Values;
	my @new_kv = List::AllUtils::mesh( @names, @values );
	$self->Splice(0, $self->Length, @new_kv);
}


}

1;
