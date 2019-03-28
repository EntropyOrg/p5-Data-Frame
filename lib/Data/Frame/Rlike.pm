package Data::Frame::Rlike;

use strict;
use warnings;

use parent qw(Exporter::Tiny);
our @EXPORT = qw(dataframe factor logical);

use Data::Frame;
use PDL::Factor ();
use PDL::Logical ();

sub dataframe {
	Data::Frame->new( columns => \@_ );
}

sub factor {
	PDL::Factor->new(@_);
}

sub logical {
	PDL::Logical->new(@_);
}

1;

__END__

=head1 DESCRIPTION

This module is superceded by L<Data::Frame::Util>.

=head1 SEE ALSO

L<Data::Frame::Util>

