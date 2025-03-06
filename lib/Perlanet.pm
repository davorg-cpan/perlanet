package Perlanet;

use 5.10.0;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use DateTime::Duration;
use DateTime;
use Perlanet::Entry;
use Perlanet::Feed;
use URI::Fetch;
use XML::Feed;

use Perlanet::Types;

our $VERSION = '3.2.0';

with 'MooseX::Traits';

$XML::Atom::ForceUnicode = 1;

has 'config' => (
  is => 'ro',
  isa => 'HashRef',
);

has 'ua' => (
  is         => 'ro',
  isa        => 'LWP::UserAgent',
  lazy_build => 1
);

sub _build_ua {
  my $self = shift;
  my $ua = LWP::UserAgent->new(
    agent   => "Perlanet/$VERSION",
    timeout => 20,
  );
  $ua->show_progress(1) if -t STDOUT;
  $ua->env_proxy;

  return $ua;
}

has 'cutoff_duration' => (
  isa     => 'Perlanet::DateTime::Duration',
  is      => 'ro',
  lazy_build => 1,
  coerce  => 1,
);

sub _build_cutoff_duration {
  return { years => 1_000 };
}

has 'cutoff' => (
  isa     => 'Perlanet::DateTime',
  is      => 'ro',
  lazy_build => 1,
  coerce  => 1,
);

sub _build_cutoff {
  return DateTime->now - shift->cutoff_duration;
}

has 'entries' => (
  isa => 'Int',
  is  => 'ro',
  default => 10,
);

has 'entries_per_feed' => (
  isa => 'Int',
  is  => 'ro',
  default => 5,
);

has 'feeds' => (
  isa     => 'ArrayRef',
  is      => 'ro',
  default => sub { [] }
);

has 'author' => (
  isa     => 'HashRef',
  is      => 'ro',
);

has $_ => (
  isa => 'Str',
  is  => 'ro',
) for qw( self_link title description url agent );

has entry_sort_order => (
  isa => 'Str',
  is  => 'ro',
  default => 'modified',
);

=head1 NAME

Perlanet - A program for creating programs that aggregate web feeds (both
RSS and Atom).

=head1 SYNOPSIS

  my $perlanet = Perlanet->new;
  $perlanet->run;

=head1 DESCRIPTION

Perlanet is a program for creating programs that aggregate web feeds (both
RSS and Atom). Web pages like this are often called "Planets" after the Python
software which originally popularised them. Perlanet is a planet builder
written in Perl - hence "Perlanet".

You are probably interested in L<Perlanet::Simple> to get started straight
out of the box, batteries included style.

Perlanet itself is the driving force behind everything, however. Perlanet
reads a series of web feeds (filtering only those that are valid), sorts
and selects entries from these web feeds, and then creates a new aggregate
feed and renders this aggregate feed. Perlanet allows the user to customize
all of these steps through subclassing and roles.

For most uses, you probably don't want to use the Perlanet module. The
L<perlanet> command line program is far more likely to be useful.

=head1 CONSTRUCTOR

=head2 new

  my $perlanet = Perlanet->new

The constructor method. Can be passed a hashref of initialisers.

See L</ATTRIBUTES> below for details of the key/value pairs to pass in.

=head1 ATTRIBUTES

=over

=item config

A hash reference that contains the complete contents of the configuration
file.

=item ua

An instance of L<LWP::UserAgent>. Defaults to a simple agent using C<<
$config->{agent} >> as the user agent name, or C< Perlanet/$VERSION >.

=item cutoff

An instance of L<DateTime> which represents the earliest date for
which feed posts will be fetched/shown.

=item feeds

An arrayref of L<Perlanet::Feed> objects representing the feeds to
collect data from.

=back

=head1 METHODS

=head2 fetch_page

Attempt to fetch a web page and a returns a L<URI::Fetch::Response> object.

=cut

sub fetch_page {
  my $self = shift;
  my ($url) = @_;
  return URI::Fetch->fetch(
    $url,
    UserAgent     => $self->ua,
    ForceResponse => 1,
  );
}

=head2 fetch_feeds

Called internally by L</run> and passed the list of feeds in L</feeds>.

Attempt to download all given feeds, as specified in the C<feeds> attribute.
Returns a list of L<Perlanet::Feed> objects, with the actual feed data
loaded.

NB: This method also modifies the contents of L</feeds>.

=cut

sub fetch_feeds {
  my $self = shift;
  my ($feeds) = @_;

  my @valid_feeds;
  for my $feed (@$feeds) {
    next unless $feed->feed;

    my $response = $self->fetch_page($feed->feed);

    if ($response->is_error) {
      warn 'Error retrieving ' . $feed->feed, "\n";
      warn $response->http_response->status_line, "\n";
      next;
    }

    unless (length $response->content) {
      warn 'No data returned from ' . $feed->feed, "\n";
      next;
    }

    try {
      my $data = $response->content;

      die 'No data from ' . $feed->feed . "\n" unless $data;

      my $xml_feed = XML::Feed->parse(\$data);

      unless ($xml_feed) {
        warn "Can't make an object from " . $feed->feed . "\n";
        my $content_type = $response->content_type;
        warn "Content type: $content_type\n" if $content_type;
        my $extract = substr $data, 0, 100;
        die "[$extract]\n";
      }

      $feed->_xml_feed($xml_feed);
      $feed->title($xml_feed->title) unless $feed->title;

      push @valid_feeds, $feed;
    }
    catch ($e) {
      warn 'Errors parsing ' . $feed->feed, "\n";
      warn "$e\n" if defined $e;
    }
  }

  return \@valid_feeds;
}

=head2 select_entries

Called internally by L</run> and passed the list of feeds from
L</fetch_feeds>.

Returns a combined list of L<Perlanet::Entry> objects from all given feeds.

=cut

sub select_entries {
  my $self = shift;
  my ($feeds) = @_;


  my $date_zero = DateTime->from_epoch(epoch => 0);

  my @feed_entries;
  for my $feed (@$feeds) {
    my @entries = $feed->_xml_feed->entries;

    for (@entries) {
      # "Fix" entries with no dates
      unless ($_->issued or $_->modified) {
        $_->issued($date_zero);
        $_->modified($date_zero);
      }

      # Problem with XML::Feed's conversion of RSS to Atom
      if ($_->issued && ! $_->modified) {
        $_->modified($_->issued);
      }
    }

    @entries = @{ $self->sort_entries(\@entries) };
    @entries = @{ $self->cutoff_entries(\@entries) };

    my $number_of_entries =
      defined $feed->max_entries ? $feed->max_entries
                                 : $self->entries_per_feed;

    if ($number_of_entries and @entries > $number_of_entries) {
      $#entries = $number_of_entries - 1;
    }

    for (@entries) {
      push @feed_entries,
        Perlanet::Entry->new(
          _entry => $_,
          feed => $feed
        );
    }
  }

  return \@feed_entries;
}

=head2 sort_entries

Called internally by L</run> and passed the list of entries from
L</select_entries>.

Sort the given list of entries into created/modified order for aggregation,
and filters them if necessary.

Takes a list of L<Perlanet::Entry>s, and returns an ordered list.

=cut

sub sort_entries {
  my $self = shift;
  my ($entries) = @_;

  my @entries;

  if ($self->entry_sort_order eq 'modified') {
    @entries = sort {
      ($b->modified || $b->issued)
          <=>
      ($a->modified || $a->issued)
    } @$entries;
  } elsif ($self->entry_sort_order eq 'issued') {
    @entries = sort {
      ($b->issued || $b->modified)
          <=>
      ($a->issued || $a->modified)
    } @$entries;
  } else {
    die 'Invalid entry sort order: ' . $self->entry_sort_order;
  }

  return \@entries;
}

=head2 cutoff_entries

Called internally by L</run> and passed the list of entries from
L</sort_entries>.

Removes any entries that were published earlier than the cut-off
date for this feed.

=cut

sub cutoff_entries {
  my $self = shift;
  my ($entries) = @_;

  my @entries = grep {
    ($_->issued || $_->modified) > $self->cutoff
  } @$entries;

  return \@entries;
}

=head2 build_feed

Called internally by L</run> and passed the list of entries from
L</sort_entries>.

Takes a list of L<Perlanet::Entry>s, and returns a L<Perlanet::Feed>
that is the actual feed for the planet.

=cut

sub build_feed {
  my $self = shift;
  my ($entries) = @_;

  my %feed_data = (
    modified => DateTime->now,
    feed     => $self->config->{url},
  );

  for (qw[title description]) {
    $feed_data{$_} = $self->$_ if defined $self->$_;
  }

  if (defined $self->author) {
    $feed_data{author} = $self->author->{name}  if defined $self->author->{name};
    $feed_data{email}  = $self->author->{email} if defined $self->author->{email};
  }

  if (defined $self->url) {
    $feed_data{self_link} = $self->url;
    $feed_data{id}        = $self->url
  }

  $feed_data{entries} = $entries;

  my $f = Perlanet::Feed->new(
    %feed_data,
  );

  return $f;

}

=head2 clean_html

Clean a HTML string so it is suitable for display.

Takes a HTML string and returns a "cleaned" HTML string.

=cut

sub clean_html {
  my $self = shift;
  my ($entry) = @_;
  return $entry;
}

=head2 clean_entries

Clean all entries for the planet.

Takes a list of entries, runs them through C<clean> and returns a list of
cleaned entries.

=cut

sub clean_entries {
  my $self = shift;
  my ($entries) = @_;

  my @clean_entries;

  foreach (@$entries) {
    if (my $body = $_->content->body) {
      my $cleaned = $self->clean_html($body);
      $_->content->body($cleaned);
    }

    if (my $summary = $_->summary->body) {
      my $cleaned = $self->clean_html($summary);
      $_->summary->body($cleaned);
    }

    push @clean_entries, $_;
  }

  return \@clean_entries;
}

=head2 render

Called internally by L</run> and passed the feed from L</build_feed>.

This is the hook where you generate some type of page to display the result
of aggregating feeds together (ie, inserting the posts into a database,
running a HTML templating library, etc)

Takes a L<Perlanet::Feed> as input (as generated by L<build_feed>.

=cut

sub render {
  my $self = shift;
  my ($feed) = @_;
}

=head2 run

The main method which runs the perlanet process.

=cut

sub run {
  my $self = shift;

  my $feeds    = $self->fetch_feeds($self->feeds);
  my $selected = $self->select_entries($feeds);
  my $sorted   = $self->sort_entries($selected);
  my $cleaned  = $self->clean_entries($sorted);
  my $feed     = $self->build_feed($cleaned);

  $self->render($feed);
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 TO DO

See L<https://github.com/davorg/perlanet/issues>

=head1 SUPPORT

To report bugs in Perlanet, please use the ticket queue at
L<https://github.com/davorg/perlanet/issues>.

=head1 SEE ALSO

=over 4

=item *

L<perlanet>

=item *

L<Plagger>

=back

=head1 AUTHOR

Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
