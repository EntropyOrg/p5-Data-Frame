use Test::Most tests => 9;

use strict;
use warnings;

use PDL::Factor;

my $data = [ qw[ a b c a b ] ];
my $f = PDL::Factor->new( $data );

is( $f->nelem, 5 );

is( $f->number_of_levels, 3 );

cmp_set( $f->levels, [qw/a b c/] );

is( "$f", "[ a b c a b ]", 'stringify' );

# set levels
my $f_set_levels = PDL::Factor->new( $data );
$f_set_levels->levels(qw/z y x/);
is_deeply( $f_set_levels->levels, [qw/z y x/] );

throws_ok
	{ $f_set_levels->levels(qw/z y/); }
	qr/incorrect number of levels/,
	'setting too few levels';

TODO: {
	todo_skip "need to implement cloning and equality", 3;

	my $copy_of_f_0 = $f->copy;
	my $copy_of_f_1 = PDL::Factor->new( $f );

	is_deeply($copy_of_f_0->levels, $f->levels);

	ok( $f == $copy_of_f_0 );

	ok( $copy_of_f_0 == $copy_of_f_1 );

	use DDP; p $copy_of_f_0->PDL::Core::string;
}

done_testing;
