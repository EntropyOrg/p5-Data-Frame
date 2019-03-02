#!perl

use Data::Frame::Setup;

use Test2::V0;

use Data::Frame::Types qw(:all);

isa_ok(DataFrame, ['Type::Tiny'], 'DataFrame type');

done_testing;
