use Test::Most tests => 2;

use strict;
use warnings;

use PDL::Factor;

my $f = PDL::Factor->new( [qw/a b c a b/] );

is( $f->nelem, 5 );

cmp_set( [ $f->levels ], [qw/a b c/] );

use DDP; p $f->PDL::Core::string;

done_testing;
