use Test::Most tests => 15;

use strict;
use warnings;

use Data::Frame::Rlike;
use PDL;

my $N  = 42;
my $first_x = 0;
my $last_x = $N - 1;
my $df = dataframe( x => sequence($N), y => 3 * sequence($N) );

is( $df->number_of_rows, $N );

# positive head
is( $df->head(2)->number_of_rows, 2 );
# row.names( head(iris, 2) ): 1 - 2
is( $df->head(2)->nth_column(0)->at(0), $first_x );
is( $df->head(2)->nth_column(0)->at(-1), $first_x + 1 );

# negative head
is( $df->head(-2)->number_of_rows, $N - 2 );
# row.names( head(iris, -1) ): 1 - 149
is( $df->head(-1)->nth_column(0)->at(0), $first_x );
is( $df->head(-1)->nth_column(0)->at(-1), $last_x - 1 );

# positive tail
is( $df->tail(2)->number_of_rows, 2 );
# row.names( tail(iris, 2) ) : 149 - 150
is( $df->tail(2)->nth_column(0)->at(0), $last_x - 1 );
is( $df->tail(2)->nth_column(0)->at(-1), $last_x );

# negative tail
is( $df->tail(-2)->number_of_rows, $N - 2 );
# row.names( tail(iris, -1) ) : 2 - 150
is( $df->tail(-1)->nth_column(0)->at(0), $first_x + 1 );
is( $df->tail(-1)->nth_column(0)->at(-1), $last_x );

is( $df->head(0)->number_of_rows, 0 );
is( $df->tail(0)->number_of_rows, 0 );

done_testing;
