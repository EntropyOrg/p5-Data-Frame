package Data::Frame::Types;

# ABSTRACT: Custom Type::Tiny types

use strict;
use warnings;

use Type::Library -base, -declare => qw(
  DataFrame
  Indexer
  Column ColumnLike
  IndexerFromLabels IndexerFromIndices
);

use Type::Utils -all;
use Types::Standard -types;
use Types::PDL qw(Piddle);

declare DataFrame, as ConsumerOf ["Data::Frame"];

declare Indexer, as ConsumerOf ["Data::Frame::Indexer::Role"];

declare ColumnLike, as ConsumerOf['PDL'], where { $_->ndims <= 1 };
declare Column, as ColumnLike;

declare_coercion "IndexerFromLabels", to_type Indexer, from Any, via {
    require Data::Frame::Indexer;
    Data::Frame::Indexer::indexer_s($_);
};
declare_coercion "IndexerFromIndices", to_type Indexer, from Any, via {
    require Data::Frame::Indexer;
    Data::Frame::Indexer::indexer_i($_);
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
* ColumnLike: This is basically piddle of 0D and 1D.
* Column: Now it's same as ColumnLike, but will likely evolve into a
dedicated type in future.

Coercions:
=for :list
* IndexerFromLabels
* IndexerFromIndices

=head1 SEE ALSO

L<Data::Frame>

