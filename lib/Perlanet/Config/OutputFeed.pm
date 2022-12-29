package Perlanet::Config::OutputFeed;

use strict;
use warnings;

use Moose;

has [qw(file format)] => (
  is => 'ro',
  isa => 'Str',
);

1;