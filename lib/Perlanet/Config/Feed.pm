package Perlanet::Config::Feed;

use strict;
use warnings;

use Moose;

use Perlanet::Types;

has title => (
  is => 'ro',
  isa => 'Str',
);

has [qw(url web)] => (
  is => 'ro',
  isa => 'Perlanet::URI',
  # coerce => 1,
);

1;