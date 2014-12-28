package Data::Frame::Role::Rlike;

use strict;
use warnings;
use Moo::Role;

sub head {

}

sub tail {

}

=method subset

    subset( CodeRef $select )

C<subset> is a helper method used to take the result of a the C<$select>
coderef and use the return value as an argument to
L<C<select_rows>/Data::Frame#select_rows>>.

The argument C<$select> is a CodeRef that is passed the Data::Frame
    $select->( $df ); # $df->subset( $select );
and returns a PDL. Within the scope of the C<$select> CodeRef, C<$_> is set to
a C<Data::Frame::Column::Helper> for the Data::Frame C<$df>.

    use Data::Frame::Rlike;
    use PDL;
    my $N  = 5;
    my $df = dataframe( x => sequence($N), y => 3 * sequence($N) );
    say $df->subset( sub {
                           ( $_->('x') > 1 )
                         & ( $_->('y') < 10 ) });
    # ---------
    #     x  y
    # ---------
    #  2  2  6
    #  3  3  9
    # ---------

=cut
sub subset($&) {
	# TODO
	my ($df, $cb) = @_;
	my $ch = $df->_column_helper;
	local *_ = \$ch;
	my $where = $cb->($df);
	$df->select_rows( $where->which );
}

1;
