package Data::Frame::Indexer::Role;

# ABSTRACT: Role for Data::Frame indexer

use Data::Frame::Role;

use Types::Standard qw(ArrayRef);
use Data::Frame::Types qw(Piddle0Dor1D);

=attr indexer

=cut

has indexer => (
    is  => 'ro',
    isa => (
        ArrayRef->plus_coercions( Piddle0Dor1D,
            sub { ( $_->badflag ? $_->where( $_->isgood ) : $_ )->unpdl }
        )
    ),
    required => 1,
    coerce   => 1,
);

1;

__END__
