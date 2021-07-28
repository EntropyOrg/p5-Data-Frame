package Data::Frame::Partial::Eval;

# ABSTRACT: Partial class for data frame's eval method

use Data::Frame::Role;
use namespace::autoclean;

use Eval::Quosure 0.001001;
use Types::Standard;

use Data::Frame::Indexer qw(indexer_s);

=method eval_tidy

    eval_tidy($x)

This method is similar to R's data frame tidy evaluation.

Depending on C<$x>,

=over 4

=item * C<$x> is a reference but not an L<Eval::Quosure> object

Return C<$x>.

=item * C<$x> is a column name of the data frame

Return the column.

=item * For other C<$x>,

Coerce C<$x> to an an L<Eval::Quosure> object, add columns of the data
frame into the quosure object's captured variables, and evaluate the
quosure object. For example, 

    # $df has a column named "foo"
    $df->eval_tidy('$foo + 1');

    # above is equivalent to below
    $df->at('foo') + 1;

=back

=cut

method eval_tidy ($x) {
    my $is_quosure = $x->$_DOES('Eval::Quosure');
    if (ref($x) and not $is_quosure) {
        return $x;
    }

    my $expr = $is_quosure ? $x->expr : $x;
    if ( $self->exists($expr) ) {
        return $self->column($expr);
    }

    my $quosure = $is_quosure ? $x : Eval::Quosure->new( $expr, 1 );

    # If expr matches a column name in the data frame, return the column.
    my $column_vars = {
        $self->names->map(
            sub {
                my $var = '$' . ( $_ =~ s/\W/_/gr );
                $var => $self->at($_);
            }
        )->flatten
    };

    try {
        return $quosure->eval($column_vars);
    }
    catch {
        die qq{Error in eval_tidy('$expr', ...) : $@ };
    }
}

1;

__END__

=head1 SYNOPSIS

    $df->eval_tidy($x);

=head1 DESCRIPTION

Do not use this module in your code. This is only internally used by
L<Data::Frame>.

The C<eval_tidy> method is similar to R's data frame tidy evaluation.

=head1 SEE ALSO

L<Data::Frame>, L<Eval::Quosure>

