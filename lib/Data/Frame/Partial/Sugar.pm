package Data::Frame::Partial::Sugar;

# ABSTRACT: Partial class for data frame syntax sugar

use Data::Frame::Role;
use namespace::autoclean;

package Tie::Data::Frame {
    use Types::PDL qw(Piddle);
    use Types::Standard qw(ArrayRef Value);
    use Type::Params;

    sub new {
        my ($class, $object) = @_;
        return bless( { _object => $object }, $class);
    }

    sub TIEHASH {
        my $class = shift;
        return $class->new(@_);
    }

    sub object { $_[0]->{_object} }

    sub _check_key {
        my $self = shift;
        state $check = Type::Params::compile(Value | ArrayRef | Piddle);
        my ($key) = $check->(@_);
        return $key;
    }

    sub STORE {
        my ( $self, $key, $val ) = @_;
        $key = $self->_check_key($key);

        if ( Ref::Util::is_ref($key) ) {
            $self->object->slice($key) .= $val;
        } else {
            $self->object->set($key, $val);
        }
    }

    sub FETCH {
        my ( $self, $key ) = @_;
        $key = $self->_check_key($key);

        if ( Ref::Util::is_ref($key) ) {
            return $self->object->slice($key);
        } else {
            return $self->object->at($key);
        }
    }

    sub EXISTS {
        my ($self, $key) = @_;
        return $self->object->exists($key);
    }

    sub FIRSTKEY {
        my ($self) = @_;
        $self->{_list} = [ @{$self->object->names} ];
        return $self->NEXTKEY;
    }

    sub NEXTKEY {
        my ($self) = @_;
        return shift @{$self->{_list}};
    }
}

use overload (
    '%{}' => sub {    # for working with Tie::Data::Frame
        my ($self)   = @_;

        # This is brittle as we are depending on an private thing of Moo... 
        my ($caller) = caller();
        if ( $caller eq 'Method::Generate::Accessor::_Generated' ) {
            return $self;
        }
        return ( $self->_tie_hash // $self );
    },
    fallback => 1
);

has _tie_hash => ( is => 'rw' );

method _initialize_sugar() {
    my %hash;
    tie %hash, qw(Tie::Data::Frame), $self;
    $self->_tie_hash( \%hash );
}

1;

__END__

=head1 SYNOPSIS

    use Data::Frame::Examples qw(mtcars);
    
    # A key of string type does at() or set()
    my $col1 = $mtcars->{mpg};                  # $mtcars->at('mpg');
    $mtcars->{kpg} = $mtcars->{mpg} * 1.609;    # $mtcars->set('kpg', ...);

    # A key of reference does slice() 
    my $col2 = $mtcars->{ ['mpg'] };            # $mtcars->slice(['mpg']);
    my $subset = $mtcars->{ [qw(mpg cyl)] };    # $mtcars->slice([qw(mpg cyl]);

=head1 DESCRIPTION

=head1 SEE ALSO

L<Data::Frame>

