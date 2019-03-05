package PDL::Factor;

use 5.016;
use warnings;

use failures qw/levels::mismatch levels::number/;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use Data::Rmap qw(rmap);
use Module::Load;
use Ref::Util qw(is_plain_arrayref);
use Safe::Isa;
use Storable qw(dclone);
use Scalar::Util qw(blessed);
use List::AllUtils ();

use parent 'PDL';
use Class::Method::Modifiers;

use Role::Tiny::With;
with qw(PDL::Role::Enumerable);

use Devel::OverloadInfo qw(overload_info);

my $overload_info;
my $super_dotassign;

BEGIN {
    my $overload_info = overload_info('PDL');
    $super_dotassign = $overload_info->{'.='}{code};
}

use overload
  '==' => \&equal,
  '!=' => \&not_equal,
#  '<'  => \&_lt,
#  'lt' => \&_lt,
#  '<=' => \&_le,
#  'le' => \&_le,
#  '>'  => \&_gt,
#  'gt' => \&_gt,
#  '>=' => \&_ge,
#  'ge' => \&_ge,
#
#  '.=' => sub {
#    my ( $self, $other, $swap ) = @_;
#
#    unless ( $other->$_DOES('PDL::SV') ) {
#        return $super_dotassign->( $self, $other, $swap );
#    }
#
#    my $internal = $self->_internal;
#    for my $i ( 0 .. $other->dim(0) - 1 ) {
#        my $idx = PDL::Core::at( $self, $i );
#        $internal->[$idx] = $other->at($i);
#    }
#    return $self;
#  },
  fallback => 1;

# after stringifiable role is added, the string method will exist
eval q{
	use overload (
        '""'   =>  \&PDL::Factor::string,
    );
};

=method new( $data, %opt )

levels => $array_ref

=cut

# check if given levels have duplicates
sub _check_levels {
    my ( $class, $levels ) = @_;

    my %levels;
    for my $i ( 0 .. $#$levels ) {
        if ( ( $levels{ $levels->[$i] }++ ) > 0 ) {
            die "levels element [$i] is duplicated";
        }
    }
}

# extract levels from piddle or arrayref
sub _extract_levels {
    my ( $class, $x ) = @_;

    state $levels_from_arrayref = sub {
        my ($aref) = @_;

        # Sort levels if levels is not given on construction.
        my @uniq = sort { $a cmp $b } List::AllUtils::uniq(@$aref);
        return \@uniq;
    };

    if ( $x->$_DOES('PDL') ) {    # PDL
        $x = $x->slice( which( $x->isgood ) ) if $x->badflag;
        if ( $x->$_DOES('PDL::SV') ) {
            return $levels_from_arrayref->( [ $x->list ] );
        }
        else {
            return $levels_from_arrayref->( [ $x->uniq->qsort->list ] );
        }
    }
    else {    # arrayref
        return $levels_from_arrayref->($x);
    }
}

sub new {
    my ( $class, @args ) = @_;

    my $data;
    # TODO UGLY! create a better interface
    #
    # new( integer => $enum, levels => $level_arrayref )
    # new( $data_arrayref, levels => $level_arrayref )
    # etc.
    #
    # Look at how R does it.
    if( @args % 2 != 0 ) {
        $data = shift @args; # first arg
    }
    my %opt = @args;
    
    if ($data->$_DOES('PDL::Factor')) {
        unless (exists $opt{levels}) {
            return $data->copy;
        }

        # reorder levels
        my @levels      = @{ delete $opt{levels} };
        my @integer_old = $data->{PDL}->list;
        my $i           = 0;
        my %levels_old  = map { $i++ => $_ } @{ $data->levels };
        $i = 0;
        my %levels_new  = map { $_ => $i++ } @levels;
        my @integer_new = map {
            my $enum = $levels_old{$_};
            defined $enum ? $levels_new{$enum} : 'nan';
        } @integer_old;
        return $class->new( integer => \@integer_new, levels => \@levels,
            %opt );
    }

    my $enum = $opt{integer} // $data;
    if ( !ref($enum) ) {    # make sure $enum is arrayref
        $enum = [$enum];
    }

    my $levels;
    if( my $levels_opt = $opt{levels} ) {
        # add the levels first if given levels option
        $class->_check_levels($levels_opt);
        $levels = $levels_opt;
    }
    else {
        $levels = $class->_extract_levels($enum);
    }

    unless (exists $opt{integer}) {
        $enum = $enum->$_DOES('PDL') ? $enum->unpdl : dclone($enum);
        my $i = 0;
        my %levels = map { $_ => $i++; } @$levels;
        rmap {
            $_ = ($levels{$_} // -1); # assign index of level
        } $enum;
    }

    my $self = $class->initialize();

    # BAD for integer enum data outside the range of level indices
    # For indx type, setnantobad() does not work, have to setvaltobad($neg).
    my $integer = PDL::Core::indx($enum)->setvaltobad(-1);
    $integer = $integer->setbadif($integer >= @$levels);

    $self->{PDL} .= $integer;
    $self->levels($levels);

    # rebless to PDL::Factor::Ordered if necessary
    my $class_ordered = 'PDL::Factor::Ordered';
    if ($opt{ordered} and not $class->DOES($class_ordered)) {
        load $class_ordered;
        bless $self, $class_ordered;
    }

    return $self;
}

sub levels {
    my $self = shift;

    if (@_) {
        my $val =
          ( @_ == 1 and is_plain_arrayref( $_[0] ) ) ? $_[0] : \@_;
        if ( defined $self->{_levels} and @$val != $self->number_of_levels ) {
            failure::levels::number->throw(
                {
                    msg   => "incorrect number of levels",
                    trace => failure->croak_trace,
                }
            );
        }
        $self->{_levels} = $val;
    }
    return $self->{_levels};
}

sub initialize {
    my ($class) = @_;
    return bless( { PDL => PDL::Core::null }, $class );
}

=method glue

    $c = $a->glue($dim, $b, ...);

Glue two or more PDLs together along an arbitrary dimension.
For now it only supports 1D PDL::Factor piddles, and C<$dim> has to be C<0>.

=cut

sub glue {
    my ($self, $dim, @piddles) = @_;
    my $class = ref($self);

    if ($dim != 0) {
        die('PDL::Factor::glue does not yet support $dim != 0');
    }

    my $data = [ map { @{$_->unpdl} } ($self, @piddles) ];
    my $new = $class->new(
            integer => $data,
            levels  => $self->levels );
    if (List::AllUtils::any { $_->badflag } ($self, @piddles)) {
        my $isbad = pdl([ map { @{$_->isbad->unpdl} } ($self, @piddles) ]);
        $new->{PDL} = $new->{PDL}->setbadif($isbad);
    }
    return $new;
}

#TODO: reimplement to reduce memory usage
sub copy {
    my ($self) = @_;
    my ($class) = ref($self);

    my $new = $class->new(
            integer => $self->{PDL}->unpdl,
            levels  => $self->levels );
    if ( $self->badflag ) {
        $new->{PDL} = $new->{PDL}->setbadif( $self->isbad );
    }
    return $new;
}

sub inplace {
    my $self = shift;
    $self->{PDL}->inplace(@_);
    return $self;
}

sub _call_on_pdl {
    my ($method) = @_;

    return sub {
        my $self = shift;
        return $self->{PDL}->$method(@_);
    };
}

for my $method (qw(isbad isgood)) {
    no strict 'refs';
    *{$method} = _call_on_pdl($method);
}

sub setbadif {
    my $self = shift;

    my $new = $self->copy;
    $new->{PDL} = $new->{PDL}->setbadif(@_);
    return $new;
}

around string => sub {
	my $orig = shift;
	my ($self, %opt) = @_;
	my $ret = $orig->(@_);
	if( exists $opt{with_levels} ) {
		my @level_string = grep { defined } $self->levels->flatten;
		$ret .= "\n";
		$ret .= "Levels: @level_string";
	}
	$ret;
};

sub _compare_levels {
    my ($a, $b) = @_;

    return unless @$a == @$b;

    my $ea = List::AllUtils::each_arrayref($a, $b);
    while ( my ($x, $y) = $ea->() ) {
        return 0 unless $x eq $y;
    }
    return 1;
}

# TODO overload, compare factor level sets
#
#R
# > g <- iris
# > levels(g$Species) <- c( levels(g$Species), "test")
# > iris$Species == g$Species
# : Error in Ops.factor(iris$Species, g$Species) :
# :   level sets of factors are different
#
# > g <- iris
# > levels(g$Species) <- levels(g$Species)[c(3, 2, 1)]
# > iris$Species == g$Species
# : # outputs a logical vector where only 'versicolor' indices are TRUE
sub equal {
	my ($self, $other, $d) = @_;
	# TODO need to look at $d to determine direction
	if( blessed($other) && $other->isa('PDL::Factor') ) {
		if( _compare_levels($self->levels, $other->levels) ) {
			return $self->{PDL} == $other->{PDL};
			# TODO return a PDL::Logical
		} else {
			failure::levels::mismatch->throw({
					msg => "level sets of factors are different",
					trace => failure->croak_trace,
					payload => {
						self_levels => $self->levels,
						other_levels => $other->levels,
					}
				}
			);
		}
	} else {
		# TODO hacky. need to test this more
        my $key_idx = List::AllUtils::first_index { $_ eq $other }
                                                  @{$self->levels};
		return $self->{PDL} == $key_idx;
	}
}

sub not_equal {
	return !equal(@_);
}


1;
