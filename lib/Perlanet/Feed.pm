package Perlanet::Feed;
use Moose;
use XML::Feed;

=head1 NAME

Perlanet::Feed - represents a feed

=cut

has 'title' => (
  isa => 'Str',
  is => 'rw',
);

has 'url' => (
  isa => 'Str',
  is => 'rw',
);

has 'web' => (
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

=head1 METHODS

=head2 as_xml

Returns a string containing the XML for this feed and all its entries

=cut

sub as_xml {
  my ($self, $format) = @_;

  my $feed = XML::Feed->new($format);
  $feed->title($self->title);
  $feed->link($self->url);
  $feed->description($self->description);
  $feed->author($self->author);
  if ($format eq 'Atom') {
    $feed->{atom}->author->email($self->email);
  }
  $feed->modified($self->modified);
  $feed->self_link($self->self_link);
  $feed->id($self->id);
  $feed->add_entry($_->_entry) for @{ $self->entries };
  return $feed->as_xml;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
