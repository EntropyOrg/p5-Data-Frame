package Data::Frame::Types;

# ABSTRACT: Custom Type::Tiny types

use strict;
use warnings;

use Type::Library -base, -declare => qw(
  DataFrame
  Indexer
  Piddle0Dor1D
  IndexerFromLabels IndexerFromIndices
);

use Type::Utils -all;
use Types::Standard -types;
use Types::PDL qw(Piddle);

declare DataFrame, as ConsumerOf ["Data::Frame"];

declare Indexer, as ConsumerOf ["Data::Frame::Indexer::Role"];

declare Piddle0Dor1D, as Piddle [ ndims_min => 0, ndims_max => 1 ];

declare_coercion "IndexerFromLabels", to_type Indexer, from Any, via {
    require Data::Frame::Indexer;
    Data::Frame::Indexer::loc($_);
};
declare_coercion "IndexerFromIndices", to_type Indexer, from Any, via {
    require Data::Frame::Indexer;
    Data::Frame::Indexer::iloc($_);
};

1;

__END__

=head1 DESCRIPTION 

This module provides custom types and coercions from the Data::Frame
project.

Types:
=for :list
* DataFrame
* Indexer
* Piddle0Dor1D

Coercions:
=for :list
* IndexerFromLabels
* IndexerFromIndices

