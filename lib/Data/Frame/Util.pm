package Data::Frame::Util;

# ABSTRACT: Utility functions

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use PDL::Factor  ();
use PDL::SV      ();
use PDL::Logical ();

use List::AllUtils qw(uniq);
use Scalar::Util qw(looks_like_number);
use Type::Params;
use Types::PDL qw(PiddleFromAny);
use Types::Standard qw(ArrayRef Value);

use Data::Frame::Types qw(ColumnLike);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = (
    qw(
      BAD NA
      ifelse is_discrete
      guess_and_convert_to_pdl
      dataframe factor logical
      ),
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=func dataframe

    my $df = dataframe(...); 

Creates a Data::Frame object.

=func factor

    my $logical = factor(...); 

Creates a L<PDL::Factor> object.

=func logical

    my $logical = logical(...); 

Creates a L<PDL::Logical> object.

=cut

sub dataframe {
    require Data::Frame;    # to avoid circular use
    Data::Frame->new( columns => \@_ );
}
sub factor  { PDL::Factor->new(@_); }
sub logical { PDL::Logical->new(@_); }

=func BAD

    my $bad = BAD($n);

A convenient function for generating all-BAD piddles of the given length.

=func NA

This is an alias of the C<BAD> function.

=cut

fun BAD ($n=1) { PDL::Core::zeros($n)->setbadat( PDL::Core::ones($n) ); }
*NA = \&BAD;

=func ifelse

    my $rslt_piddle = ifelse($test, $yes, $no)

This function tries to do the same as R's C<ifelse> function. That is,
it returns a piddle of the same length as C<$test>, and is filled with
elements selected from C<$yes> or C<$no> depending on whether the
corresponding element in C<$test> is true or false.

C<$test>, C<$yes>, C<$no> should ideally be piddles or coerce-able to
piddles. 

=cut

fun ifelse ($test, $yes, $no) {
    state $check = Type::Params::compile(
        ( ColumnLike->plus_coercions(PiddleFromAny) ),
        ( ( ColumnLike->plus_coercions(PiddleFromAny) ) x 2 )
    );
    ( $test, $yes, $no ) = $check->( $test, $yes, $no );

    my $l   = $test->length;
    my $idx = which( !$test );

    $yes = $yes->repeat_to_length($l);
    if ( $idx->length == 0 ) {
        return $yes;
    }

    $no = $no->repeat_to_length($l);
    my $no_sliced = $no->slice($idx);
    $no_sliced = $no_sliced->convert($yes->type->enum)
        if $yes->type != $no->type;
    $yes->slice($idx) .= $no_sliced;

    return $yes;
}

=func is_discrete

    my $bool = is_discrete(ColumnLike $x);

Returns true if C<$x> is discrete, that is, an object of below types,

=for :list
* PDL::Factor
* PDL::SV

=cut

fun is_discrete (ColumnLike $x) {
    return (
             $x->$_DOES('PDL::Factor')
          or $x->$_DOES('PDL::SV')
          or $x->type eq 'byte'
    );
}

=func guess_and_convert_to_pdl

=cut

sub _is_na {
    my ($na, $include_empty) = @_;

    my @na = uniq(@$na, ($include_empty ? '' : ()));

    # see utils/benchmarks/is_na.pl for why grep is used here
    return sub {
        scalar( grep { $_[0] eq $_ } @na );
    };
}

sub _numeric_from_arrayref {
    my ($x, $na, $f) = @_;
    $f //= \&PDL::Core::pdl;

    my $is_na = _is_na($na, 1);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    my $p = do {
        local $SIG{__WARN__} = sub { };
        $f->($x);
    };
    return $p->setbadif($isbad);
}

sub _logical_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 1);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    my $p = PDL::Logical->new($x);
    return $p->setbadif($isbad);
}

sub _datetime_from_arrayref {
    my ($x, $na) = @_;
    return _numeric_from_arrayref( $x, $na,
        sub { PDL::DateTime->new_from_datetime( $_[0] ) } );
}

sub _factor_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 0);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    if ( $isbad->any ) {    # remove $na from levels
        my $levels = [ sort grep { !&$is_na($_) } uniq(@$x) ];
        return PDL::Factor->new( $x, levels => $levels )->setbadif($isbad);
    } else {
        return PDL::Factor->new($x);
    }
}

sub _pdlsv_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 0);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    return PDL::SV->new($x)->setbadif($isbad);
}

fun guess_and_convert_to_pdl ( (ArrayRef | Value | ColumnLike) $x,
        :$strings_as_factors=false, :$test_count=1000, :$na=[qw(NA BAD)]) {
    return $x if ( $x->$_DOES('PDL') );

    my $is_na0 = _is_na($na, 1);
    my $like_number;
    if ( !ref $x ) {
        $like_number = looks_like_number($x);
        $x           = [$x];
    }
    else {
        $like_number = List::AllUtils::all {
            looks_like_number($_) or &$is_na0($_);
        }
        @$x[ 0 .. List::AllUtils::min( $test_count - 1, $#$x ) ];
    }

    # The $na parameter is only effective for logical and numeric columns.
    # This is in align with R's from_csv behavior.
    if ($like_number) {
        return _numeric_from_arrayref($x, $na);
    }
    else {
        if ($strings_as_factors) {
            return _factor_from_arrayref($x, $na);
        }
        else {
            return _pdlsv_from_arrayref($x, $na);
        }
    }
}

1;

__END__

=head1 DESCRIPTION

This module provides some utility functions used by the L<Data::Frame> project.

