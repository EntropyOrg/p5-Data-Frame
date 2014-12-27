package Data::Frame::Rlike;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(dataframe factor);

sub dataframe {
	Data::Frame->new(@_);
}

sub factor {
	PDL::Factor->new(@_);
}

# R-like
sub rbind {
	# TODO
	...
}

1;
