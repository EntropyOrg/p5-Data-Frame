package Data::Frame::Types;

# ABSTRACT: Custom Type::Tiny types

use strict;
use warnings;

use Type::Library -base, -declare => qw(
  DataFrame
  Indexer
  DataType
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

declare DataType, as Enum [
    qw(
      ushort long indx longlong float double
      string factor logical datetime
      )
];

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
* ColumnLike
This is basically piddle of 0D and 1D.
* Column
Now it's same as ColumnLike, but will likely evolve into a dedicated type
in future.
* DataType
One of the PDL types
C<"ushort">, C<"long">, C<"indx">, C<"longlong">, C<"float">, C<"double">,
or C<"string"> (PDL::SV), C<"factor"> (PDL::Factor),
C<"logical"> (PDL::Logical), C<"datetime"> (PDL::DateTime).

Coercions:
=for :list
* IndexerFromLabels
* IndexerFromIndices

=head1 SEE ALSO

L<Data::Frame>

