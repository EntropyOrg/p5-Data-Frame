use Test::Most tests => 8;

use strict;
use warnings;

use Data::Frame;
use PDL;

my $a = pdl(1, 2, 3, 4);
my $b = $a >= 2;
my $c = [ qw/foo bar baz quux/ ];

my $df = Data::Frame->new( columns => [
	z => $a,
	y => $b,
	x => $c,
] );
Moo::Role->apply_roles_to_object( $df, qw(Data::Frame::Role::Rlike) );

my @rows = (3,1);
my $df_select_array    = $df->select_rows(@rows);
my $df_select_arrayref = $df->select_rows([@rows]);
my $df_select_pdl      = $df->select_rows(pdl [@rows]);
is( $df_select_array->number_of_rows, scalar @rows );
is( $df_select_arrayref->number_of_rows, scalar @rows );
is( $df_select_pdl->number_of_rows, scalar @rows );

is( $df->select_rows()->number_of_rows, 0 );
is( $df->select_rows([])->number_of_rows, 0 );

my $df_subset = $df->subset(sub { $_->('z') > 2 });
is_deeply( $df_subset->row_names->unpdl, [ 2..3 ]);

my $df_subset_autoload = $df->subset(sub { $_->z > 2 });
is_deeply( $df_subset_autoload->row_names->unpdl, [ 2..3 ]);

my $df_subset_further = $df_subset->subset( sub { $_->('z') == 3 } );

is_deeply( $df_subset_further->row_names->unpdl, [ 2 ]);

done_testing;
