package Data::Frame;

use strict;
use warnings;

use Tie::IxHash;
use PDL;
use Data::Perl;
use List::AllUtils;

{
	# TODO temporary column role
	no strict;
	*PDL::number_of_rows = sub { $_[0]->getdim(0) };
	*Data::Perl::Collection::Array::number_of_rows = sub { $_[0]->count };
}

use Moo;

has _columns => ( is => 'ro', default => sub { Tie::IxHash->new; } );

has _row_names => ( is => 'rw', default => sub { [] } );

around new => sub {
	my $orig = shift;
	my ($class, %args) = @_;
	my $colspec = delete $args{columns};

	my $self = $orig->(@_);

	if( defined $colspec ) {
		my @columns =
			  ref $colspec eq 'HASH'
			? map { ($_, $colspec->{$_} ) } sort { $a cmp $b } keys %$colspec
			: @$colspec;
		$self->add_columns(@columns);
	}

	$self;
};

sub number_of_columns {
	my ($self) = @_;
	$self->_columns->Length;
}

sub number_of_rows {
	my ($self) = @_;
	if( $self->number_of_columns ) {
		return $self->nth_column(0)->number_of_rows;
	}
	0;
}

sub nth_column {
	my ($self, $index) = @_;
	die "requires index" unless defined $index;
	$self->_columns->Values( $index );
}

=method column_names

  column_names()

  column_names( @new_column_names )

=cut
sub column_names {
	my ($self, @colnames) = @_;
	if( @colnames ) {
		die "not enough column names" unless  @colnames ==  $self->number_of_columns;
		my @values = $self->_columns->Values;
		my @new_kv = List::AllUtils::mesh( @colnames, @values );
		$self->_columns->Splice(0, $self->_columns->Length, @new_kv);
	}
	$self->_columns->Keys;
}

sub row_names {
	...
}

sub column {
	my ($self, $colname) = @_;
	$self->_columns->FETCH( $colname );
}

sub _column_validate {
	my ($self, $name, $data) = @_;
	if( $name =~ /^\d+$/  ) {
		die "invalid column name: $name can not be an integer";
	}
	if( $self->number_of_columns ) {
		if( $data->number_of_rows != $self->number_of_rows ) {
			die "number of rows in column is @{[ $data->number_of_rows ]}; expected @{[ $self->number_of_rows ]}";
		}
	}
	1;
}

sub add_columns {
	my ($self, @columns) = @_;
	die "uneven number of elements for column specification" unless @columns % 2 == 0;
        for ( List::AllUtils::pairs(@columns) ) {
		my ( $name, $data ) = @$_;
		$self->add_column( $name => $data );
        }
}

sub add_column {
	my ($self, $name, $data) = @_;
	die "column $name already exists"
		if $self->_columns->EXISTS( $name );

	# TODO apply column role to data
	$data = Data::Perl::array( @$data ) if ref $data eq 'ARRAY';

	$self->_column_validate( $name => $data);


	$self->_columns->Push( $name => $data );
}

1;
