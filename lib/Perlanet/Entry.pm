package Perlanet::Entry;

use strict;
use warnings;

use Moose;

=head1 NAME

Perlanet::Entry - represents an entry in a feed

=head1 DESCRIPTION

This is a wrapper around L<XML::Feed::Entry> with support for linking back to
the feed from the entry

=cut

has '_entry' => (
  isa => 'XML::Feed::Entry',
  is => 'ro',
  required => 1,
  handles => [qw( title link issued body summary content modified author )]
);

has 'feed' => (
  isa => 'Perlanet::Feed',
  is => 'ro',
  required => 1
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
