package Data::Frame::Rlike;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(dataframe factor);

use Data::Frame;
use PDL::Factor;

our $_df_rlike_class = Moo::Role->create_class_with_roles( 'Data::Frame',
	qw(Data::Frame::Role::Rlike));

sub dataframe {
	$_df_rlike_class->new( columns => \@_ );
}

sub factor {
	PDL::Factor->new(@_);
}

# R-like
sub rbind {
	# TODO
	...
}

1;
