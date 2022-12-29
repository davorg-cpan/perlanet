package Perlanet::Config::Author;

use strict;
use warnings;

use Moose;

has [qw(name email)] => (
  is => 'ro',
  isa => 'Str',
);

1;