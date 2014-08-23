package PDL::Factor;

use strict;
use warnings;

use Moo;
use PDL::Lite;
use MooX::InsideOut;
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

around new => sub {
	my $orig = shift;
	my ($class, @args) = @_;
	my $data = shift @args; # first arg

	my $levels = Tie::IxHash->new;
	my $enum = dclone($data);
	rmap {
		my $v = $_;
		$levels->Push($v => 1);    # add value to hash if it doesn't exist
		$_ = $levels->Indices($v); # assign index of level
	} $enum;

	unshift @args, _data => $enum;
	unshift @args, _levels => $levels;

	my $self = $orig->($class, @args);

	$self;
};

sub FOREIGNBUILDARGS {
	my ($self, %args) = @_;
	( $args{_data} );
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
	...
}


1;
