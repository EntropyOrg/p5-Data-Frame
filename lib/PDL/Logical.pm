package PDL::Logical;

# ABSTRACT: PDL subclass for keeping logical data

use 5.016;
use warnings;

use PDL::Lite ();   # PDL::Lite is the minimal to get PDL work
use PDL::Core qw(pdl);

use Ref::Util qw(is_plain_arrayref);
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
    elsif ( is_plain_arrayref($data) ) {

        # this is faster than Data::Rmap::rmap().
        state $rmap = sub {
            my ($x) = @_;
            is_plain_arrayref($x)
              ? [ map { __SUB__->($_) } @$x ]
              : ( $x ? 1 : 0 );
        };

        $data = pdl( $rmap->($data) );
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
