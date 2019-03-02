package Data::Frame::Autobox::Hash;

# ABSTRACT: Additional Hash role for Moose::Autobox

use Moose::Role;

use List::AllUtils qw(pairmap);
use Ref::Util;
use namespace::autoclean;

=method isempty

    my $isempty = $hash->isempty;

Returns a boolean value for if the hash ref is empty.

=cut

sub isempty { keys %{ $_[0] } == 0 }

=method names

    my $keys = $hash->names;

This is same as the C<keys> method of Moose::Autobox::Hash.

=cut

sub names { [ keys %{ $_[0] } ] }

=method set($key, $value)

    $hash->set($key, $value);

This is same as the C<put> method of Moose::Autobox::Hash.

=cut

sub set {
    my ( $hash, $key, $value ) = @_;
    $hash->{$key} = $value;
}

=method rename($hashref_or_coderef)

    my $new_href1 = $href->rename( { $from_key => $to_key, ... } );
    my $new_href2 = $href->rename( sub { $_[0] . 'foo' } );

It can take either a hashref of key mappings. If a keys does not exist in
the mappings, it would not be renamed. 
Also this method can take a coderef which transforms the keys.

=cut

sub rename {
    my ( $hash, $href_or_coderef ) = @_;

    my %new_hash;
    if ( Ref::Util::is_coderef($href_or_coderef) ) {
        %new_hash = pairmap { ( $href_or_coderef->($a) // $a ) => $b } %$hash;
    }
    else {
        %new_hash = pairmap { ( $href_or_coderef->{$a} // $a ) => $b } %$hash;
    }
    return \%new_hash;
}


=method copy

Shallow copy.

=cut

sub copy { { %{ $_[0] } } }

1;

__END__

=head1 SYNOPSIS

    use Moose::Autobox;

    Moose::Autobox->mixin_additional_role(
        HASH => "Data::Frame::Autobox::Hash"
    );

    { one => 1 }->names;            # [ 'one' ]
    { one => 1 }->isempty;          # false

=head1 DESCRIPTION

This is an additional Hash role for Moose::Autobox.

=head1 SEE ALSO

L<Moose::Autobox>

L<Moose::Autobox::Hash>

