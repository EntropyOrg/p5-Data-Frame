use Test::Most tests => 6;

use strict;
use warnings;

use PDL;
use PDL::StringfiableExtension;

is( sequence(10)->element_stringify_max_width, 1 );
is( sequence(11)->element_stringify_max_width, 2 );
is( sequence(12)->element_stringify_max_width, 2 );
is( sequence(100)->element_stringify_max_width, 2 );
is( sequence(101)->element_stringify_max_width, 3 );

my @each = (
	{ val => 1.23         , zerodim =>  4, ndim =>  4  },
	{ val => 1.23456      , zerodim =>  7, ndim =>  7  },
	{ val => 1.23456789   , zerodim => 10, ndim => 10  },
	{ val => 1.234567890  , zerodim => 10, ndim => 10  },
	{ val => 1.2345678901 , zerodim => 12, ndim => 10  },
	{ val => 1.23456789012, zerodim => 13, ndim => 10  },
);

subtest 'lengths' => sub {
	plan tests => 3 * @each;
	for my $data (@each) {
		diag $data->{val};
		is( pdl($data->{val})->element_stringify_max_width, $data->{zerodim} );
		is( pdl([ $data->{val} ])->element_stringify_max_width, $data->{ndim} );
		is( pdl([ [ $data->{val} ] ])->element_stringify_max_width, $data->{ndim} );
	}
};

print sequence($PDL::toolongtoprint + 1);

done_testing;
