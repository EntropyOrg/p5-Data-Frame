use Test::Most tests => 8;

use strict;
use warnings;

use PDL::SV;

use Math::BigInt;

my $data = [ Math::BigInt->new('0'), Math::BigInt->new('1'), Math::BigInt->new('2'), ];
my $f = PDL::SV->new( $data );

is( $f->nelem, 3 );


done_testing;
