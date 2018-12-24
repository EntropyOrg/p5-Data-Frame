package PDL::Factor;

use 5.010;
use strict;
use warnings;

use failures qw/levels::mismatch/;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which whichND);
use Data::Rmap qw(rmap);
use Safe::Isa;
use Storable qw(dclone);
use Scalar::Util qw(blessed);
use List::AllUtils ();
use Test::Deep::NoTest qw(eq_deeply);

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

    my $levels = Tie::IxHash->new;
    my $enum = $opt{integer} // dclone($data);
    if (!ref($enum)) {  # make sure $enum is arrayref
        $enum = [ $enum ];
    }

    if( my $levels_opt = $opt{levels} ) {
        # add the levels first if given levels option
        for my $l ( @$levels_opt ) {
            $levels->Push( $l => 1 );
        }
        # TODO what if the levels passed in are not unique?
        # TODO what if the integer enum data outside the range of level indices?
    } else {
        # Sort levels if levels is not given on construction.
        my @uniq = sort { $a cmp $b } List::AllUtils::uniq(@$enum);
        for my $i (0 .. $#uniq) {
            $levels->Push($uniq[$i]);  # add value to hash if it doesn't exist
        }
        rmap {
            my $v = $_;
            $_ = $levels->Indices($v); # assign index of level
        } $enum;
    }

    my $self = $class->initialize();
    $self->{PDL} .= PDL::Core::indx($enum); 
    $self->{_levels} = $levels;

    return $self;
}

sub _levels {
    my ($self, $val) = @_; 
    if (defined $val) {
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

#=method setbadtoval
#
#Cannot be run inplace.
#
#=cut
#
#sub setbadtoval {
#    my $self = shift;
#    my ($val) = @_;
#
#    my $class = ref($self);
#
#    my $data = $self->unpdl;
#    if ( $self->badflag ) {
#        my $isbad = $self->isbad;
#        for my $idx ( which($isbad)->list ) {
#            my @where = reverse $self->one2nd($idx);
#            $self->_array_set( $data, \@where, $val );
#        }
#    }
#    return $class->new($data);
#}

around string => sub {
	my $orig = shift;
	my ($self, %opt) = @_;
	my $ret = $orig->(@_);
	if( exists $opt{with_levels} ) {
		my @level_string = grep { defined } $self->{_levels}->Keys();
		$ret .= "\n";
		$ret .= "Levels: @level_string";
	}
	$ret;
};

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
		if( eq_deeply($self->_levels, $other->_levels) ) {
			return $self->{PDL} == $other->{PDL};
			# TODO return a PDL::Logical
		} else {
			failure::levels::mismatch->throw({
					msg => "level sets of factors are different",
					trace => failure->croak_trace,
					payload => {
						self_levels => $self->_levels,
						other_levels => $other->_levels,
					}
				}
			);
		}
	} else {
		# TODO hacky. need to test this more
		my $key_idx = $self->_levels->Indices($other);
		return $self->{PDL} == $key_idx;
	}
}

sub not_equal {
	return !equal(@_);
}


1;
