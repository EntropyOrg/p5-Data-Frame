package Data::Frame;
# ABSTRACT: data frame implementation

use strict;
use warnings;

use Tie::IxHash;
use Tie::IxHash::Extension;
use PDL::Lite;
use Data::Perl ();
use List::AllUtils;
use Try::Tiny;
use PDL::SV;
use PDL::StringfiableExtension;
use Carp;
use Scalar::Util qw(blessed);

use Text::Table::Tiny;

use Data::Frame::Column::Helper;

use overload (
		'""'   =>  \&Data::Frame::string,
		'=='   =>  \&Data::Frame::equal,
		'eq'   =>  \&Data::Frame::equal,
	);

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

sub string {
	my ($self) = @_;
	my $rows = [];
	push @$rows, [ '', @{ $self->column_names } ];
	for my $r_idx ( 0..$self->number_of_rows-1 ) {
		my $r = [
			$self->row_names->slice($r_idx)->squeeze->string,
			map {
				my $col = $self->nth_column($_);
				$col->slice($r_idx)->squeeze->string
			} 0..$self->number_of_columns-1 ];
		push @$rows, $r;
	}
	{
		# clear column separators
		local $Text::Table::Tiny::COLUMN_SEPARATOR = '';
		local $Text::Table::Tiny::CORNER_MARKER = '';

		Text::Table::Tiny::table(rows => $rows, header_row => 1)
	}
}

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

# supports negative indices
sub nth_column {
	my ($self, $index) = @_;
	confess "requires index" unless defined $index;
	confess "column index out of bounds" if $index >= $self->number_of_columns;
	# fine if $index < 0 because negative indices are supported
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
			confess "incorrect number of column names" if /@{[ Tie::IxHash::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_columns->Keys ];
}

sub row_names {
	my ($self, @rest) = @_;
	if( @rest ) {
		# setting row names
		my $new_rows;
		if( ref $rest[0] ) {
			if( ref $rest[0] eq 'ARRAY' ) {
				$new_rows = Data::Perl::array( @{ $rest[0] });
			} elsif( $rest[0]->isa('PDL') ) {
				# TODO just run uniq?
				$new_rows = Data::Perl::array( @{ $rest[0]->unpdl } );
			} else {
				$new_rows = Data::Perl::array(@rest);
			}
		} else {
			$new_rows = Data::Perl::array(@rest);
		}

		confess "invalid row names length"
			if $self->number_of_rows != $new_rows->count;
		confess "non-unique row names"
			if $new_rows->count != $new_rows->uniq->count;

		return $self->_row_names( PDL::SV->new($new_rows) );
	}
	if( not $self->_has_row_names ) {
		# if it has never been set before
		return sequence($self->number_of_rows);
	}
	# else, if row_names has been set
	return $self->_row_names;
}

sub _make_actual_row_names {
	my ($self) = @_;
	if( not $self->_has_row_names ) {
		$self->_row_names( $self->row_names );
	}
}

sub column {
	my ($self, $colname) = @_;
	confess "column $colname does not exist" unless $self->_columns->EXISTS( $colname );
	$self->_columns->FETCH( $colname );
}

sub _column_validate {
	my ($self, $name, $data) = @_;
	if( $name =~ /^\d+$/  ) {
		confess "invalid column name: $name can not be an integer";
	}
	if( $self->number_of_columns ) {
		if( $data->number_of_rows != $self->number_of_rows ) {
			confess "number of rows in column is @{[ $data->number_of_rows ]}; expected @{[ $self->number_of_rows ]}";
		}
	}
	1;
}

sub add_columns {
	my ($self, @columns) = @_;
	confess "uneven number of elements for column specification" unless @columns % 2 == 0;
	for ( List::AllUtils::pairs(@columns) ) {
		my ( $name, $data ) = @$_;
		$self->add_column( $name => $data );
	}
}

sub add_column {
	my ($self, $name, $data) = @_;
	confess "column $name already exists"
		if $self->_columns->EXISTS( $name );

	# TODO apply column role to data
	$data = PDL::SV->new( $data ) if ref $data eq 'ARRAY';

	$self->_column_validate( $name => $data);


	$self->_columns->Push( $name => $data );
}

# R
# > iris[c(1,2,3,3,3,3),]
# PDL
# $ sequence(10,4)->dice(X,[0,1,1,0])
sub select_rows {
	my ($self, $which) = @_;
	my $colnames = $self->column_names;
	my $colspec = [ map {
		( $colnames->[$_] => $self->nth_column($_)->dice($which) )
	} 0..$self->number_of_columns-1 ];

	$self->_make_actual_row_names;
	my $select_df = Data::Frame->new(
		columns => $colspec,
		_row_names => $self->row_names->dice( $which ) );
}

sub _column_helper {
	my ($self) = @_;
	Data::Frame::Column::Helper->new( df => $self );
}

sub equal {
	my ($self, $other, $d) = @_;
	if( blessed($self) && $self->isa('Data::Frame') && blessed($other) && $other->isa('Data::Frame') ) {
		if( $self->number_of_columns == $other->number_of_columns ) {
			my @eq_cols = map { $self->nth_column($_) == $other->nth_column($_) }
					0..$self->number_of_columns-1;
			my @colnames = @{ $self->columns };
			my @colspec = List::AllUtils::mesh( @colnames, @eq_cols );
			return Data::Frame->new( columns => \@colspec );
		} else {
			die "number of columns is not equal: @{[$self->number_of_columns]} != @{[$other->number_of_columns]}";
		}
	}
}

1;
