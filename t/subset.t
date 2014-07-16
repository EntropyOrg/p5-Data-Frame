use Test::Most;

package _subset_test;
use Import::Into;

sub new {
	my $s = bless {};
	my $caller = caller();
	no strict 'refs';
	*{$caller.'::a'} = 1;
	*{$caller.'::b'} = 1;
	*{$caller.'::c'} = 1;
	$s;
}

sub subset {
	my ($self, $code) = @_;

	my ( $caller_a, $caller_b, $caller_c ) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg.'::a'}, \*{$pkg.'::b'}, \*{$pkg.'::c'};
	};

	local( *$caller_a, *$caller_b, *$caller_c );
	[ grep {
		*$caller_c = \$_;
		$code->();
	} 0..10 ];
}

package main;

my $s = _subset_test->new;

my $g = $s->subset(sub { no strict; $c > 8 });

use DDP; p $g;

done_testing;
