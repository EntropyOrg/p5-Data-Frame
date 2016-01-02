#!/usr/bin/env perl

use strict; use warnings;
use Test::More;

use Data::Frame;
use Test::Fatal;

my $a = Data::Frame->new( columns => [
		x => [ qw/foo br baz/ ],
	],
);

my $b = Data::Frame->new( columns => [
		x => [qw/ a b c /],
		y => [1..3],
	],
);


isa_ok( exception { $a == $b }, 'failure::columns::mismatch');

done_testing;

