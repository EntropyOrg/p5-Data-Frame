package Data::Frame::Autobox;

# ABSTRACT: Autobox arrays and hashes for Data::Frame

use strict;
use warnings;

# VERSION

use parent 'autobox';

=head1 SYNOPSIS

    use Data::Frame::Autobox;

    [ 1 .. 5 ]->isempty;    # false

    { one => 1 }->names;    # [ 'one' ]
    { one => 1 }->isempty;  # false

=head1 DESCRIPTION

This package provides a set of methods for autoboxed arrays and hashes.

=cut

sub import {
    shift->SUPER::import(
        ARRAY => __PACKAGE__ . '::ARRAY',
        HASH  => __PACKAGE__ . '::HASH',
        @_
    );
}


package Data::Frame::Autobox::ARRAY;

use List::AllUtils;
use POSIX qw(ceil);

=head1 ARRAY METHODS

=head2 isempty

    my $isempty = $array->isempty;

Returns a boolean value for if the array ref is empty.

=head2 grep
    
    my $new_array = $array->grep($coderef);

=head2 map
    
    my $new_array = $array->map($coderef);

=head2 at

    my $value = $array->at($idx);

=head2 uniq

    my $uniq_array = $array->uniq;

=head2 set

    $array->set($idx, $value);

=head2 length

    my $length = $array->length;

=head2 elems
    
This is same as C<length>.

=head2 flatten

    my @array = $array->flatten;

Explicitly returns an array.

=head2 slice

    my $slice = $array->slice($indices);

=cut

sub isempty { @{$_[0]} == 0 }

sub grep {
    my ($array, $sub) = @_;
    [ CORE::grep { $sub->($_) } @$array ];
}
 
sub map {
    my ($array, $sub) = @_;
    [ CORE::map { $sub->($_) } @$array ];
}

sub at {
    my ($array, $index) = @_;
    $array->[$index];
}
 
sub uniq { [ List::AllUtils::uniq(@{$_[0]}) ] }

sub set {
    my ($array, $index, $value) = @_;
    $array->[$index] = $value;
}

sub length { CORE::scalar @{$_[0]} }
sub elems { CORE::scalar @{$_[0]} }
 
sub flatten  { @{$_[0]} }
 
sub slice {
    my ($array, $indices) = @_;
    [ @{$array}[ @{$indices} ] ];
}

=head2 copy

Shallow copy.

=head2 repeat

    my $new_array = $array->repeat($n);

Repeat for C<$n> times.

=head2 repeat_to_length

    my $new_array = $array->repeat_to_length($l);

Repeat to get the length of C<$l>.

=head2 intersect

    my $new_array = $array->intersect($other)

=head2 union

    my $new_array = $array->union($other)

=head2 setdiff
    
    my $new_array = $array->setdiff($other)

=cut

sub copy { [ @{$_[0]} ] }

sub repeat {
    my ($array, $n) = @_;
    return [ (@$array) x $n ];
}

sub repeat_to_length {
    my ($array, $l) = @_;
    return $array if @$array == 0;
    my $x = repeat($array, ceil($l / @$array));
    return [ @$x[0 .. $l-1] ];
}
 
sub intersect {
    my ($array, $other) = @_;
    my %hash = map { $_ => 1 } @$array;
    return [ grep { exists $hash{$_} } @$other ];
}

sub union {
    my ($array, $other) = @_;
    return [ List::AllUtils::uniq( @$array, @$other ) ];
}

sub setdiff {
    my ($array, $other) = @_;
    my %hash = map { $_ => 1 } @$other;
    return [ grep { not exists( $hash{$_} ) } @$array ];
}
 

package Data::Frame::Autobox::HASH;

use Carp;
use Ref::Util;
use List::AllUtils qw(pairmap);

=head1 HASH METHODS

=head2 isempty

    my $isempty = $hash->isempty;

Returns a boolean value for if the hash ref is empty.

=head2 delete

    $hash->delete($key);

=head2 merge

    my $merged_hash = $hash->merge($other);

=head2 hslice

    my $sliced_hash = $hash->hslice($keys);

=head2 at

    my $value = $hash->at($key);

=head2 set

    $hash->set($key, $value);

=head2 exists

    my $bool = $hash->exists($key);

=head2 keys

    my $keys = $hash->keys;

=head2 names

This is same as C<keys>.

=head2 values

    my $values = $hash->values;

=head2 flatten

    my %hash = $hash->flatten;

Explicitly returns an array.

=head2 slice

    my $values = $hash->slice($keys);

=cut

sub isempty { keys %{ $_[0] } == 0 } 

sub delete {
    my ($hash, $key) = @_;
    CORE::delete $hash->{$key};
}
 
sub merge {
    my ($left, $right) = @_;
    Carp::confess "You must pass a hashref as argument to merge"
        unless ref $right eq 'HASH';
    return { %$left, %$right };
}
 
sub hslice {
    my ($hash, $keys) = @_;
    return { map { $_ => $hash->{$_} } @$keys };
}

sub flatten { %{$_[0]} }

sub at {
    my ($hash, $index) = @_;
    $hash->{$index};
}
 
sub set {
    my ($hash, $index, $value) = @_;
    $hash->{$index} = $value;
}
 
sub exists {
    my ($hash, $key) = @_;
    CORE::exists $hash->{$key};
}
 
sub keys { [ CORE::keys %{$_[0]} ] }
sub names { [ CORE::keys %{$_[0]} ] }
 
sub values {
    my ($hash) = @_;
    [ CORE::values %$hash ];
}
 
sub slice {
    my ($hash, $keys) = @_;
    return [ @{$hash}{@$keys} ];
}

=head2 copy

Shallow copy.

=head2 rename

    rename($hashref_or_coderef)

It can take either,

=for :list
* A hashref of key mappings.
If a keys does not exist in the mappings, it would not be renamed.
* A coderef which transforms each key.

    my $new_href1 = $href->rename( { $from_key => $to_key, ... } );
    my $new_href2 = $href->rename( sub { $_[0] . 'foo' } );

=cut

sub copy { { %{ $_[0] } } }

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

1;

__END__

=head1 SEE ALSO

L<autobox>

