package Data::Frame::Autobox::Array;

# ABSTRACT: Additional Array role for Moose::Autobox

use 5.016;
use Moose::Role;
use Function::Parameters;

use List::AllUtils;
use POSIX qw(ceil);

use namespace::autoclean;

=method isempty

    my $isempty = $array->isempty;

Returns a boolean value for if the array ref is empty.

=method uniq

    my $uniq_array = $array->uniq;

=method set($idx, $value)

    $array->set($idx, $value);

This is same as the C<put> method of Moose::Autobox::Array.

=cut

method isempty() { @{$self} == 0 }

method uniq() { [ List::AllUtils::uniq(@{$self}) ] }

method set($index, $value) { 
    $self->[$index] = $value;
}

=method repeat

    my $new_array = $array->repeat($n);

Repeat for C<$n> times.

=method repeat_to_length

    my $new_array = $array->repeat_to_length($l);

Repeat to get the length of C<$l>. 

=cut

method repeat($n) {
    return [ (@$self) x $n ];
}

method repeat_to_length($l) {
    return $self if @$self == 0;
    my $x = repeat($self, ceil($l / @$self));
    return [ @$x[0 .. $l-1] ];
}

=method copy

Shallow copy.

=cut

method copy() { [ @{$self} ] }

=method intersect

    my $new_ary = $array->intersect($other)

=method union

    my $new_array = $array->union($other)

=method setdiff
    
    my $new_array = $array->setdiff($other)

=cut

method intersect ( $other ) { 
    my %hash = map { $_ => 1 } @$self;
    return [ grep { exists $hash{$_} } @$other ];
}

method union ($other) {
    return [ List::AllUtils::uniq( @$self, @$other ) ];
}

method setdiff ($other) {
    my %hash = map { $_ => 1 } @$other;
    return [ grep { not exists( $hash{$_} ) } @$self ];
}

1;

__END__

=pod
=encoding utf8

=head1 SYNOPSIS

    use Moose::Autobox;
    
    Moose::Autobox->mixin_additional_role(
        ARRAY => "Data::Frame::Autobox::Array"
    );

    [ 1 .. 5 ]->isempty;    # false

=head1 DESCRIPTION

This is an additional Array role for Moose::Autobox, used by Data::Frame.

=head1 SEE ALSO

L<Moose::Autobox>,
L<Moose::Autobox::Array>

