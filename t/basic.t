use Test::Most tests => 12;

use strict;
use warnings;

use Data::Frame;
use PDL;

my $a = pdl(1, 2, 3, 4);
my $b = $a >= 2;
my $c = [ qw/foo bar baz quux/ ];

my $df_array = Data::Frame->new( columns => [
	z => $a,
	y => $b,
	x => $c,
] );

my $df_hash = Data::Frame->new( columns => {
	b => $b,
	c => $c,
	a => $a,
} );

is($df_array->number_of_columns, 3);
is($df_hash->number_of_columns, 3);

is($df_array->number_of_rows, 4);
is($df_hash->number_of_rows, 4);

is_deeply( $df_array->column_names, [ qw/z y x/ ] );
is_deeply( $df_hash->column_names, [ qw/a b c/ ] );

is( $df_hash->column('c')->number_of_rows, 4);
is_deeply( $df_hash->column('c'), $c);

throws_ok { $df_hash->add_column( c => [1, 2, 3, 4] ) }
	qr/column.*already exists/,
	'exception for adding existing column';

$df_array->column_names(qw/a b c/);
is_deeply( $df_array->column_names, [ qw/a b c/ ], 'renaming columns works' );

is_deeply( $df_array->row_names, [ 0..3 ] );

throws_ok
	{ $df_array->column_names(qw/a b c d/); }
	qr/incorrect number of column names/,
	'setting more columns than exist';

done_testing;
