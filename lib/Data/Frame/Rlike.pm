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
}

# R-like
sub subset {
	# TODO
	my ($df, $cb) = @_;
	my $ch = $df->_column_helper;
	local *_ = \$ch;
	my $where = $cb->($df);
	$df->select_rows( $where->which );
}

*Data::Frame::subset = \&subset;

1;
