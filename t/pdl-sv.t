use Test::Most tests => 8;

use strict;
use warnings;

use PDL::SV;

use Math::BigInt;

my $data = [ Math::BigInt->new('4'), Math::BigInt->new('3'), Math::BigInt->new('2'), ];
my $f = PDL::SV->new( $data );

is( $f->nelem, 3 );

is( $f->at(0), 4 );

is( "$f", "[ 4 3 2 ]" );

is( "@{[ $f->slice('1:2') ]}", "[ 3 2 ]" );


done_testing;
