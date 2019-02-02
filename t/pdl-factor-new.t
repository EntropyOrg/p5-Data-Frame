#!perl

use 5.010;
use strict;
use warnings;

use PDL::Core qw(pdl);
use PDL::Factor ();
use PDL::SV     ();

use Test2::V0;
use Test2::Tools::PDL;

subtest construction => sub {
    my $x1 = pdl( [qw(6 6 4 6 8 6 8 4 4 6)] );

    my $f1 = PDL::Factor->new($x1);
    ok( defined($f1), 'new($pdl)' );
    is( $f1->levels, [qw(4 6 8)], 'levels' );
    is( $f1->unpdl, [qw(1 1 0 1 2 1 2 0 0 1)], 'unpdl' );

    my $f1a = PDL::Factor->new( $x1, levels => [qw(8 6 4)] );
    ok( defined($f1a), 'new($pdl, levels => $levels)' );
    is( $f1a->levels, [qw(8 6 4)], 'levels' );
    is( $f1a->unpdl, [qw(1 1 2 1 0 1 0 2 2 1)], 'unpdl' );

    my $x2 = $x1->copy->setbadat(1);

    my $f2a = PDL::Factor->new($x2);
    ok( defined($f2a), 'new($pdl_with_bad)' );
    is( $f2a->levels, [qw(4 6 8)], 'levels' );
    pdl_is( $f2a->isbad, pdl( [ 0, 1, (0) x 8 ] ), 'isbad' );
    is( $f2a->unpdl, [qw(1 BAD 0 1 2 1 2 0 0 1)], 'unpdl' );

    my $f2b = PDL::Factor->new( $x2, levels => [qw(8 6 4)] );
    ok( defined($f2b), 'new($pdl_with_bad, levels => $levels)' );
    is( $f2b->levels, [qw(8 6 4)], 'levels' );
    is( $f2b->unpdl, [qw(1 BAD 2 1 0 1 0 2 2 1)], 'unpdl' );

    # reorder factor levels
    my $f2c = PDL::Factor->new( $f2a, levels => [qw(8 6 4)] );
    ok( defined($f2c), 'reorder factor levels' );
    is( $f2c->levels, [qw(8 6 4)], 'levels' );
    is( $f2c->unpdl, [qw(1 BAD 2 1 0 1 0 2 2 1)], 'unpdl' );

    my $x3 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(2);

    my $f3a = PDL::Factor->new($x3);
    ok( defined($f3a), 'new($pdlsv)' );
    is( $f3a->levels, [qw(bar foo)], 'levels' );
    is( $f3a->unpdl,  [qw(1 0 BAD)], 'unpdl' );
};

done_testing;
