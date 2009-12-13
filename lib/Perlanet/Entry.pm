package Perlanet::Entry;
use Moose;

has '_entry' => (
  isa => 'XML::Feed::Entry',
  is => 'ro',
  required => 1,
  handles => [qw( title issued body summary content modified )]
);

has 'feed' => (
  isa => 'Perlanet::Feed',
  is => 'ro',
  required => 1
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
