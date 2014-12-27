package Data::Frame::Role::Rlike;

use strict;
use warnings;
use Moo::Role;

sub head {

}

sub tail {

}

# R-like
sub subset($&) {
	# TODO
	my ($df, $cb) = @_;
	my $ch = $df->_column_helper;
	local *_ = \$ch;
	my $where = $cb->($df);
	$df->select_rows( $where->which );
}

1;
