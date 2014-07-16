use Test::Most;

use strict;
use PDL::Factor;

my $f = PDL::Factor->new( [qw/a b c a b/] );

is( $f->nelem, 5 );

cmp_set( $f->levels, [a b c] );


done_testing;
