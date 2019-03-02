package Data::Frame::Util;

# ABSTRACT: Utility functions

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use PDL::Factor ();
use PDL::SV     ();

use Data::Munge qw(elem);
use List::AllUtils;
use Scalar::Util qw(looks_like_number);
use Type::Params;
use Types::PDL qw(PiddleFromAny);
use Types::Standard qw(ArrayRef Value);

use Data::Frame::Types qw(Piddle0Dor1D);
use Data::Frame::Rlike;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = (
    qw(
      BAD NA
      ifelse is_discrete
      guess_and_convert_to_pdl
      ),
    @Data::Frame::Rlike::EXPORT
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

C<$test>, C<$yes>, C<$no> should ideally be piddles or cocere-able to
piddles. 

=cut

fun ifelse ($test, $yes, $no) {
    state $check = Type::Params::compile(
        ( Piddle0Dor1D->plus_coercions(PiddleFromAny) ),
        ( ( Piddle0Dor1D->plus_coercions(PiddleFromAny) ) x 2 )
    );
    ( $test, $yes, $no ) = $check->( $test, $yes, $no );

    my $l   = $test->length;
    my $idx = which( !$test );

    $yes = $yes->repeat_to_length($l);
    if ( $idx->length == 0 ) {
        return $yes;
    }

    $no = $no->repeat_to_length($l);
    $yes->slice($idx) .= $no->slice($idx);

    return $yes;
}

=func is_discrete

    my $bool = is_discrete(Piddle0Dor1D $x);

Returns true if C<$x> is discrete, that is, an object of below types,

=for :list
* PDL::Factor
* PDL::SV

=cut

fun is_discrete (Piddle0Dor1D $x) {
    return (
             $x->$_DOES('PDL::Factor')
          or $x->$_DOES('PDL::SV')
          or $x->type eq 'byte'
    );
}

=func guess_and_convert_to_pdl

=cut

fun guess_and_convert_to_pdl ( (ArrayRef | Value | Piddle0Dor1D) $x,
        :$strings_as_factors=false, :$test_count=1000, :$na=[qw(BAD NA)]) {
    return $x if ( $x->$_DOES('PDL') );

    my $like_number;
    if ( !ref $x ) {
        $like_number = looks_like_number($x);
        $x           = [$x];
    }
    else {
        $like_number = List::AllUtils::all {
            my $x = $_;
            looks_like_number($x)
              or length($x) == 0
              or (
                # should be somewhat faster than elem()
                List::AllUtils::any { $x eq $_ } @$na
              )
        }
        @$x[ 0 .. List::AllUtils::min( $test_count - 1, $#$x ) ];
    }

    my $is_na = sub { length( $_[0] ) == 0 or elem( $_[0], $na ); };

    if ($like_number) {
        my @data   = map { &$is_na($_) ? 'nan' : $_ } @$x;
        my $piddle = pdl( \@data );
        $piddle->inplace->setnantobad;
        return $piddle;
    }
    else {
        my $piddle =
          $strings_as_factors
          ? PDL::Factor->new($x)
          : PDL::SV->new($x);
        my @is_bad = List::AllUtils::indexes { &$is_na($_) } @$x;
        if (@is_bad) {
            $piddle = $piddle->setbadif( pdl( \@is_bad ) );
        }
        return $piddle;
    }
}

1;

__END__

=head1 DESCRIPTION

This module provides some utility functions used by the Data::Frame project.

