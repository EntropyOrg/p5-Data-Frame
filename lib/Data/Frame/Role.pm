package Data::Frame::Role;

# ABSTRACT: For creating roles in Data::Frame

use Data::Frame::Setup ();

sub import {
    my ( $class, @tags ) = @_;
    Data::Frame::Setup->_import( scalar(caller), qw(:role), @tags );
}

1;

__END__

=pod

=head1 SYNOPSIS
    
    use Data::Frame::Role;

=head1 DESCRIPTION

C<use Data::Frame::Role ...;> is equivalent of 

    use Data::Frame::Setup qw(:role), ...;

=head1 SEE ALSO

L<Data::Frame::Setup>

