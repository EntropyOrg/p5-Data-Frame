use Test::Most tests => 1;

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

my $df_subset = $df->subset(sub { $_->('z') > 2 });

is_deeply( $df_subset->row_names, [ 2..3 ]);

my $df_subset_further = $df_subset->subset( { $_->('z') == 3 } );

is_deeply( $df_subset_further->row_names, [ 2 ]);

done_testing;
