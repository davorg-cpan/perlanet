package Perlanet::Config::Page;

use strict;
use warnings;

use Moose;

has [qw(file template)] => (
  is => 'ro',
  isa => 'Str',
);

1;