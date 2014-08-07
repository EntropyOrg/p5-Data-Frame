package PDL::Factor;

use strict;
use warnings;

use Moo;
use PDL::Lite;
use MooX::InsideOut;
use Tie::IxHash;
use Data::Rmap qw(rmap);
use Storable qw(dclone);

extends 'PDL';
with 'PDL::Role::Enumerable';

#use overload ("\"\""   =>  \&PDL::Factor::string);

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

sub string {
	my $self   = shift;
	my $level  = shift || 0;
	$self->PDL::Core::string;
}

sub FOREIGNBUILDARGS {
	my ($self, %args) = @_;
	( $args{_data} );
}


1;
