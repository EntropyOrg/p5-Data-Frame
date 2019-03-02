#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use Test2::V0;

use Data::Frame::Indexer qw(:all);

subtest loc => sub {
    is( loc()->indexer->length, 0, 'loc()' );
    is( loc( [] )->indexer->length, 0, 'loc([])' );
    is( loc(undef)->indexer->length, 0, 'loc(undef)' );
    is( loc( pdl( [ 1, 2 ] ) )->indexer, [ 1, 2 ], 'loc($pdl)' );

    my $indexer = loc( [qw(x y)] );
    isa_ok( $indexer, ['Data::Frame::Indexer::ByLabel'] );
    is( $indexer->indexer, [qw(x y)], 'loc([qw(x y)])' );
    is( iloc($indexer), $indexer, 'iloc($indexer)' );
};

subtest iloc => sub {
    is( iloc()->indexer->length, 0, 'iloc()' );
    is( iloc( [] )->indexer->length, 0, 'iloc([])' );
    is( iloc(undef)->indexer->length, 0, 'iloc(undef)' );

    my $indexer = iloc( [ 1, 2 ] );
    isa_ok( $indexer, ['Data::Frame::Indexer::ByIndex'] );
    is( $indexer->indexer, [ 1, 2 ], 'loc([1, 2])' );

    is( loc($indexer), $indexer, 'loc($indexer)' );
};

done_testing;
