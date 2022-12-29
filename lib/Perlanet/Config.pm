package Perlanet::Config;

use strict;
use warnings;

use Moose;

use Perlanet::Types;
use Perlanet::Config::Author;
use Perlanet::Config::Page;
use Perlanet::Config::OutputFeed;
use Perlanet::Config::Feed;

has [qw(title description opml)] => (
  is => 'ro',
  isa => 'Str',
);

has url => (
  is => 'ro',
  isa => 'Perlanet::URI',
  coerce => 1,
);

has author => (
  is => 'ro',
  isa => 'Perlanet::Config::Author',
  coerce => 1,
);

has entries => (
  is => 'ro',
  isa => 'Int',
);

has page => (
  is => 'ro',
  isa => 'Perlanet::Config::Page',
  coerce => 1,
);

has feed => (
  is => 'ro',
  isa => 'Perlanet::Config::OutputFeed',
  coerce => 1,
);

has feeds => (
  is => 'ro',
  isa => 'Perlanet::Config::Feeds',
  coerce => 1,
);

1;