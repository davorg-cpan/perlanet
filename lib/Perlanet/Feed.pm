package Perlanet::Feed;

use 5.10.0;
use strict;
use warnings;

use Moose;
use XML::Feed;

=head1 NAME

Perlanet::Feed - represents a feed

=cut

has 'title' => (
  isa => 'Str',
  is => 'rw', # Ew!
);

has 'feed' => (
  isa => 'Str',
  is => 'ro',
  required => 1,
);

has 'web' => (
  isa => 'Str',
  is => 'ro',
);

has 'format' => (
  is => 'ro',
);

has 'description' => (
  is => 'ro',
);

has 'author' => (
  is => 'ro',
);

has 'email' => (
  is => 'ro',
);

has '_xml_feed' => (
  isa => 'XML::Feed',
  is => 'rw', # Ew!
);

has 'id' => (
  is => 'ro',
);

has 'self_link' => (
  is => 'ro',
);

has 'modified' => (
  is => 'ro',
);

has 'max_entries' => (
  is => 'ro',
  isa => 'Int',
);

has 'entries' => (
  isa => 'ArrayRef',
  is => 'ro',
  default => sub { [] },
  traits => [ 'Array' ],
  handles => {
    add_entry => 'push',
  }
);

# Handle the url -> feed renaming
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  my $args;
  if (@_ == 1) {
    $args = $_[0];
  } else {
    $args = { @_ };
  }

  if ($args->{url} and ! $args->{feed}) {
    warn "Your config file uses 'url' for the URL of the feed. ",
         "Please update that to 'feed'.\n";
    $args->{feed} = $args->{url};
  }

  return $args;
};

=head1 METHODS

=head2 as_xml

Returns a string containing the XML for this feed and all its entries

=cut

sub as_xml {
  my $self = shift;
  my ($format) = @_;

  my $feed = XML::Feed->new($format);
  $feed->title($self->title);
  $feed->link($self->feed);
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

=head2 url

We've renamed the old 'url' attribute to 'feed'.

This allows the old name to still work, but generates a warning.

=cut

sub url {
  my $self = shift;

  warn "The url() method has been renamed to feed()\n";

  return $self->feed;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
