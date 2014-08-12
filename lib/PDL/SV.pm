package PDL::SV;

use strict;
use warnings;

use Moo;
use PDL::Lite;
use MooX::InsideOut;

extends 'PDL';

# TODO

has _data => ( is => 'rw' );


1;
