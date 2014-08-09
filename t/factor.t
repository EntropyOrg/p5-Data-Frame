use Test::Most tests => 5;

use strict;
use warnings;

use PDL::Factor;

my $f = PDL::Factor->new( [qw/a b c a b/] );

is( $f->nelem, 5 );

is( $f->number_of_levels, 3 );

cmp_set( $f->levels, [qw/a b c/] );

use DDP; p $f->PDL::Core::string;

# set levels
$f->levels(qw/z y x/);
is_deeply( $f->levels, [qw/z y x/] );

throws_ok
	{ $f->levels(qw/z y/) }
	qr/incorrect number of levels/,
	'setting too few levels';

done_testing;
