package PDL::Factor;

use strict;
use warnings;

use Moo;
use PDL::Lite;
use Tie::IxHash;
use Tie::IxHash::Extension;
use Data::Rmap qw(rmap);
use Storable qw(dclone);

extends 'PDL';
with 'PDL::Role::Enumerable';

# after stringifiable role is added, the string method will exist
eval q{
	use overload ( '""'   =>  \&PDL::Factor::string );
};

=method new( $data, %opt )

levels => $array_ref

=cut
around new => sub {
	my $orig = shift;
	my ($class, @args) = @_;
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
	if( exists $opt{levels} ) {
		# add the levels first if given levels option
		for my $l (@{ $opt{levels} } ) {
			$levels->Push( $l => 1 );
		}
		# TODO what if the levels passed in are not unique?
		# TODO what if the integer enum data outside the range of level indices?
	} else {
		rmap {
			my $v = $_;
			$levels->Push($v => 1);    # add value to hash if it doesn't exist
			$_ = $levels->Indices($v); # assign index of level
		} $enum;
	}

	unshift @args, _data => $enum;
	unshift @args, _levels => $levels;

	# TODO how do I pass the prefered type to PDL->new()?
	my $self = $orig->($class, @args);
	$self->{PDL} = $self->{PDL}->long;

	$self;
};

sub FOREIGNBUILDARGS {
	my ($self, %args) = @_;
	( $args{_data} );
}

sub initialize {
	bless { PDL => PDL::null() }, shift;
}

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
	if( $self->_levels == $other->_levels ) {
		...
		# return a PDL::Logical
	} else {
		die "level sets of factors are different";
	}
}


1;
