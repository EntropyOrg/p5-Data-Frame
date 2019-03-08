package PDL::Logical;

# ABSTRACT: PDL subclass for keeping logical data

use 5.016;
use warnings;

use PDL::Core qw(pdl);
use Data::Rmap qw(rmap_array);
use Safe::Isa;

use parent 'PDL';
use Class::Method::Modifiers;

sub new {
    my ( $class, @args ) = @_;

    my $data;
    if ( @args % 2 != 0 ) {
        $data = shift @args;    # first arg
    }
    my %opt = @args;

    if ( $data->$_DOES('PDL') ) {
        $data = !!$data;
    }
    elsif ( ref($data) eq 'ARRAY' ) {
        my ($data1) = rmap_array {
            ( ref( $_->[0] ) eq 'ARRAY' )
              ? [ $_[0]->recurse() ]
              : [ map { $_ ? 1 : 0 } @$_ ];
        }
        $data;
        $data = pdl($data1);
    }
    else {
        $data = pdl( $data ? 1 : 0 );
    }

    my $self = $class->initialize();
    $self->{PDL} .= $data;

    return $self;
}

sub initialize {
    my ($class) = @_;
    return bless( { PDL => PDL::Core::null }, $class );
}

1;

__END__

=pod
=encoding utf8

=head1 SYNOPSIS

    use PDL::Logical ();
    
    # below does what you mean, while pdl([true, false]) does not
    use boolean;
    my $logical = PDL::Logical->new([ true, false ]);

=head1 DESCRIPTION

This class represents piddle of logical values. It provides a way to
treat data as booleans and convert them to piddles.
    
=head1 SEE ALSO

L<PDL>
