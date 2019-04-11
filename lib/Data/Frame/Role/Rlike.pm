package Data::Frame::Role::Rlike;

=encoding utf8

=cut

use Data::Frame::Role;

use List::AllUtils;

=head1 METHODS

=tmpl head_and_tail

=head2 head

    head( Int $n=6 )

If $n ≥ 0, returns a new C<Data::Frame> with the first $n rows of the
C<Data::Frame>.

If $n < 0, returns a new C<Data::Frame> with all but the last -$n rows of the
C<Data::Frame>.

See also: R's L<head|https://stat.ethz.ch/R-manual/R-devel/library/utils/html/head.html> function.

=head2 tail

    tail( Int $n=6 )

If $n ≥ 0, returns a new C<Data::Frame> with the last $n rows of the
C<Data::Frame>.

If $n < 0, returns a new C<Data::Frame> with all but the first -$n rows of the
C<Data::Frame>.

See also: R's L<tail|https://stat.ethz.ch/R-manual/R-devel/library/utils/html/head.html> function.

=tmpl

=cut

method head($n=6) {
	my ($start, $stop);
	if( $n < 0 ) {
		$start = 0;
		$stop = $self->number_of_rows + $n - 1;
	} else {
		$start = 0;
		$stop  = $n - 1;
	}
	# clip to [ 0, number_of_rows-1 ]
	$start = List::AllUtils::max( 0, $start );
	$stop  = List::AllUtils::min( $self->number_of_rows-1, $stop );
	return $self->select_rows( $start..$stop );
}

method tail($n=6) {
	my ($start, $stop);
	if( $n < 0 ) {
		$start = -$n;
		$stop = $self->number_of_rows - 1;
	} else {
		$start = $self->number_of_rows - $n;
		$stop = $self->number_of_rows - 1;
	}
	# clip to [ 0, number_of_rows-1 ]
	$start = List::AllUtils::max( 0, $start );
	$stop  = List::AllUtils::min( $self->number_of_rows-1, $stop );
	return $self->select_rows( $start..$stop );
}

=head2 subset

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

See also: R's L<subset|https://stat.ethz.ch/R-manual/R-devel/library/base/html/subset.html> function

=cut
sub subset($&) {
	my ($df, $cb) = @_;
	my $ch = $df->_column_helper;
	local *_ = \$ch;
	my $where = $cb->($df);
	$df->select_rows( $where->which );
}

1;
=head1 SYNOPSIS

Data::Frame::Role::Rlike - role to provide R-like methods for Data::Frame

=cut
