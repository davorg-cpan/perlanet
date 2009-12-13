package Perlanet::Feed;
use Moose;

has 'title' => (
  isa => 'Str',
  is => 'rw',
);

has 'url' => (
  isa => 'Str',
  is => 'rw',
);

has 'website' => (
  isa => 'Str',
  is => 'rw',
);

has 'format' => (
  is => 'rw',
);

has 'description' => (
  is => 'rw',
);

has 'author' => (
  is => 'rw',
);

has 'email' => (
  is => 'rw',
);

has '_xml_feed' => (
  isa => 'XML::Feed',
  is => 'rw',
);

has 'id' => (
  is => 'rw',
);

has 'self_link' => (
  is => 'rw',
);

has 'modified' => (
  is => 'rw',
);

has 'entries' => (
  isa => 'ArrayRef',
  is => 'rw',
  default => sub { [] },
  traits => [ 'Array' ],
  handles => {
    add_entry => 'push',
  }
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
