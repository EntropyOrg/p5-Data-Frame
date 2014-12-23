use Test::Most tests => 5;

use strict;
use warnings;

use Data::Frame;
use Data::Frame::Rlike;
use PDL;

my $a = pdl(1, 2, 3, 4);
my $b = $a >= 2;
my $c = [ qw/foo bar baz quux/ ];

my $df = Data::Frame->new( columns => [
	z => $a,
	y => $b,
	x => $c,
] );

my @rows = (3,1);
my $df_select_array    = $df->select_rows(@rows);
my $df_select_arrayref = $df->select_rows([@rows]);
my $df_select_pdl      = $df->select_rows(pdl [@rows]);
is( $df_select_array->number_of_rows, @rows );
is( $df_select_arrayref->number_of_rows, @rows );
is( $df_select_pdl->number_of_rows, @rows );

my $df_subset = $df->subset(sub { $_->('z') > 2 });

is_deeply( $df_subset->row_names->unpdl, [ 2..3 ]);

my $df_subset_further = $df_subset->subset( sub { $_->('z') == 3 } );

is_deeply( $df_subset_further->row_names->unpdl, [ 2 ]);

done_testing;
