package PDL::SV;

use strict;
use warnings;

use Moo;
use PDL::Lite;
use MooX::InsideOut;
use Data::Rmap qw(rmap_array);
use Storable qw(dclone);

extends 'PDL';

use overload ("\"\""   =>  \&PDL::SV::string);

has _internal => ( is => 'rw', default => sub { [] } );

around new => sub {
	my $orig = shift;
	my ($class, @args) = @_;
	my $data = shift @args; # first arg

	my $faked_data = dclone($data);
	rmap_array { $_ = [ (0)x@$_ ] } $faked_data;

	unshift @args, _data => $faked_data;

	my $self = $orig->($class, @args);

	$self .= $self->sequence( $self->dims );

	my $nelem = $self->nelem;
	for my $idx (0..$nelem-1) {
		my @where = pdl($self->one2nd($idx))->list;
		$self->_internal()->[$idx] = $self->_array_get( $data, @where );
	}

	$self;
};

# code modified from <https://metacpan.org/pod/Hash::Path>
sub _array_get {
	my ($self, $array, @indices) = @_;
	return $array unless scalar @indices;
	my $return_value = $array->[ $indices[0] ];
	for (1 .. (scalar @indices - 1)) {
		$return_value = $return_value->[ $indices[$_] ];
	}
	return $return_value;
}

sub string {
  my ($self) = @_;
  if( $self->ndims == 1 ) {
    return $self->string1d;
  }
}

sub string1d {
  my ($self) = @_;
  my $str = "[";

  for my $w (0..$self->nelem-1) {
    $str .= " ";
    $str .= $self->at($w);
  }
  $str .= " " if ($self->nelem > 0);
  $str .= "]";
  $str;
}



sub FOREIGNBUILDARGS {
	my ($self, %args) = @_;
	( $args{_data} );
}

around at => sub {
	my $orig = shift;
	my ($self) = @_;

	my $data = $orig->(@_);
	$self->_internal->[$data];
};


1;
