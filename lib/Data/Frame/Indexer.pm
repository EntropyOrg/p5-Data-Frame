package Data::Frame::Indexer;

# ABSTRACT: Function interface for indexer

use Data::Frame::Setup;

use Types::PDL qw(Piddle1D);

use Data::Frame::Indexer::ByIndex;
use Data::Frame::Indexer::ByLabel;
use Data::Frame::Types qw(:all);
use Data::Frame::Util qw(is_discrete);

use parent qw(Exporter::Tiny);

our @EXPORT_OK   = qw(loc iloc);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=func loc($x)

Returns either C<undef> or an indexer object, by trying below rules,

=for :list
* If called with C<undef>, returns C<undef>.
* If the argument is an indexer object, just returns it.
* If the argument is a PDL of numeric types, create an indexer object
of L<Data::Frame::Indexer::ByIndex> 
* Fallbacks to create an indexer object of
L<Data::Frame::Indexer::ByLabel>.

=func iloc($x)

Similar to C<loc> but would fallback to an indexer object of
L<Data::Frame::Indexer::ByIndex>.

=cut

my $NumericIndices =
  Piddle0Dor1D->where( sub { $_->type ne 'byte' and not is_discrete($_) } );

fun _as_indexer ($fallback_indexer_class) {
    return sub {
        my $x = @_ > 1 ? \@_ : @_ == 1 ? $_[0] : [];

        return undef unless defined $x;
        return $x if ( Indexer->check($x) );

        unless ( Ref::Util::is_plain_arrayref($x) or $x->$_DOES('PDL') ) {
            $x = [$x];
        }
        if ( $NumericIndices->check($x) ) {
            return Data::Frame::Indexer::ByIndex->new( indexer => $x->unpdl );
        }
        $fallback_indexer_class->new( indexer => $x );
    };
}

*loc  = _as_indexer('Data::Frame::Indexer::ByLabel');
*iloc = _as_indexer('Data::Frame::Indexer::ByIndex');

1;

__END__

=head1 DESCRIPTION

A basic feature needed in a data frame library is the ability of subsetting
a data frame by either numeric indices or string labels of columns and rows.
Because of the ambiguity of number and string in Perl, there needs a way to 
allow user to explicitly specify whether their indexer is by numeric
indices or string labels. This modules provides functions that serves this
purpose. 
 
