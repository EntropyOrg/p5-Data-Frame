package Data::Frame::Class;

# ABSTRACT: For creating classes in Data::Frame

use Data::Frame::Setup ();

sub import {
    my ( $class, @tags ) = @_;
    Data::Frame::Setup->_import( scalar(caller), qw(:class), @tags );
}

1;

__END__

=pod

=head1 SYNOPSIS
    
    use Data::Frame::Class;

=head1 DESCRIPTION

C<use Data::Frame::Class ...;> is equivalent of 

    use Data::Frame::Setup qw(:class), ...;

=head1 SEE ALSO

L<Data::Frame::Setup>

