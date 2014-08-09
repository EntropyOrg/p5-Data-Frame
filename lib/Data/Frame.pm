package Data::Frame;

use strict;
use warnings;

use Tie::IxHash;
use Tie::IxHash::Extension;
use PDL;
use Data::Perl;
use List::AllUtils;
use Try::Tiny;

{
	# TODO temporary column role
	no strict;
	*PDL::number_of_rows = sub { $_[0]->getdim(0) };
	*Data::Perl::Collection::Array::number_of_rows = sub { $_[0]->count };
}

use Moo;

has _columns => ( is => 'ro', default => sub { Tie::IxHash->new; } );

has _row_names => ( is => 'rw', predicate => 1 );

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
		try {
			$self->_columns->RenameKeys( @colnames );
		} catch {
			die "incorrect number of column names" if /@{[ Tie::IxHash::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_columns->Keys ];
}

sub row_names {
	my ($self, @rest) = @_;
	if( @rest ) {
		# setting row names
		my $new_rows = Data::Perl::array(
				  ref $rest[0] eq 'ARRAY'
				? @{ $rest[0] }
				: @rest );
		die "invalid row names length"
			if $self->number_of_rows != $new_rows->count;
		die "non-unique row names"
			if $new_rows->count != $new_rows->uniq->count;

		return $self->_row_names($new_rows);
	}
	if( not $self->_has_row_names ) {
		# if it has never been set before
		return array( 0..$self->number_of_rows-1);
	}
	# else, if row_names has been set
	return $self->_row_names;
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
