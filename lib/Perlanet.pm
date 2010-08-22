package Perlanet;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Carp;
use DateTime::Duration;
use DateTime;
use Perlanet::Entry;
use Perlanet::Feed;
use TryCatch;
use URI::Fetch;
use XML::Feed;

use vars qw{$VERSION};

BEGIN {
  $VERSION = '0.51';
}

with 'MooseX::Traits';

$XML::Atom::ForceUnicode = 1;

has 'ua' => (
  is         => 'rw',
  isa        => 'LWP::UserAgent',
  lazy_build => 1
);

sub _build_ua {
  my $self = shift;
  my $ua = LWP::UserAgent->new(
    agent => "Perlanet/$VERSION"
  );
  $ua->show_progress(1) if -t STDOUT;
  $ua->env_proxy;

  return $ua;
}

has 'cutoff' => (
  isa     => 'DateTime',
  is      => 'ro',
  default => sub {
    DateTime->now + DateTime::Duration->new(weeks => 1);
  }
);

has 'entries' => (
  isa => 'Int',
  is  => 'rw',
  default => 10,
);

has 'entries_per_feed' => (
  isa => 'Int',
  is  => 'rw',
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

=item ua

An instance of L<LWP::UserAgent>. Defaults to a simple agent using C<<
$cfg->{agent} >> as the user agent name, or C< Perlanet/$VERSION >.

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
  my ($self, $url) = @_;
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
  my ($self, @feeds) = @_;

  my @valid_feeds;
  for my $feed (@feeds) {
    my $response = $self->fetch_page($feed->url);

    next if $response->is_error;

    try {
      my $data = $response->content;
      my $xml_feed = XML::Feed->parse(\$data);

      $feed->_xml_feed($xml_feed);
      $feed->title($xml_feed->title) unless $feed->title;

      push @valid_feeds, $feed;
    }
    catch ($e) {
      carp 'Errors parsing ' . $feed->url;
      carp $e if defined $e;
    }
  }

  return @valid_feeds;
}

=head2 select_entries

Called internally by L</run> and passed the list of feeds from
L</fetch_feeds>.

Returns a combined list of L<Perlanet::Entry> objects from all given feeds.

=cut

sub select_entries {
  my ($self, @feeds) = @_;

  my @feed_entries;
  for my $feed (@feeds) {
    my @entries = $feed->_xml_feed->entries;

    if ($self->entries_per_feed and @entries > $self->entries_per_feed) {
      $#entries = $self->entries_per_feed - 1;
    }

    push @feed_entries,
      map {
        $_->title($feed->title . ': ' . $_->title);

        # Problem with XML::Feed's conversion of RSS to Atom
        if ($_->issued && ! $_->modified) {
          $_->modified($_->issued);
        }

        Perlanet::Entry->new(
          _entry => $_,
          feed => $feed
        );
      } @entries;
  }

  return @feed_entries;
}

=head2 sort_entries

Called internally by L</run> and passed the list of entries from
L</select_entries>.

Sort the given list of entries into created/modified order for aggregation,
and filters them if necessary.

Takes a list of L<Perlanet::Entry>s, and returns an ordered list.

=cut

sub sort_entries {
  my ($self, @entries) = @_;
  my $day_zero = DateTime->from_epoch(epoch => 0);

  @entries = grep {
      ($_->issued || $_->modified || $day_zero) < $self->cutoff
  } sort {
      ($b->modified || $b->issued || $day_zero)
          <=>
      ($a->modified || $a->issued || $day_zero)
  } @entries;

  # Only need so many entries
  if ($self->entries && @entries > $self->entries) {
    $#entries = $self->entries - 1;
  }

  return @entries;
}

=head2 build_feed

Called internally by L</run> and passed the list of entries from
L</sort_entries>.

Takes a list of L<Perlanet::Entry>s, and returns a L<Perlanet::Feed>
that is the actual feed for the planet.

=cut

sub build_feed {
  my ($self, @entries) = @_;

  my $self_url = $self->self_link;

  my $f = Perlanet::Feed->new( modified    => DateTime->now );
  $f->title($self->title)             if defined $self->title;
  $f->url($self->url)                 if defined $self->url;
  $f->description($self->description) if defined $self->description;
  $f->author($self->author->{name})   if defined $self->author->{name};
  $f->email($self->author->{email})   if defined $self->author->{email};
  $f->self_link($self->url)           if defined $self->url;
  $f->id($self->url)                  if defined $self->url;

  $f->add_entry($_) for @entries;

  return $f;
}

=head2 clean_html

Clean a HTML string so it is suitable for display.

Takes a HTML string and returns a "cleaned" HTML string.

=cut

sub clean_html {
  my ($self, $entry) = @_;
  return $entry;
}

=head2 clean_entries

Clean all entries for the planet.

Takes a list of entries, runs them through C<clean> and returns a list of
cleaned entries.

=cut

sub clean_entries {
  my ($self, @entries) = @_;

  my @clean_entries;

  foreach (@entries) {
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

  return @clean_entries;
}

=head2 render

Called internally by L</run> and passed the feed from L</build_feed>.

This is the hook where you generate some type of page to display the result
of aggregating feeds together (ie, inserting the posts into a database,
running a HTML templating library, etc)

Takes a L<Perlanet::Feed> as input (as generated by L<build_feed>.

=cut

sub render {
  my ($self, $feed) = @_;
}

=head2 run

The main method which runs the perlanet process.

=cut

sub run {
  my $self = shift;

  my @feeds    = $self->fetch_feeds(@{$self->feeds});
  my @selected = $self->select_entries(@feeds);
  my @sorted   = $self->sort_entries(@selected);
  my @cleaned  = $self->clean_entries(@sorted);
  my $feed     = $self->build_feed(@cleaned);

  $self->render($feed);
}

=head1 TO DO

See http://wiki.github.com/davorg/perlanet

=head1 SUPPORT

There is a mailing list which acts as both a place for developers to talk
about maintaining and improving Perlanet and also for users to get support.
You can sign up to this list at
L<http://lists.mag-sol.com/mailman/listinfo/perlanet>

To report bugs in Perlanet, please use the CPAN request tracker. You can
either use the web page at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Perlanet> or send an email
to bug-Perlanet@rt.cpan.org.

=head1 SEE ALSO

=over 4

=item *

L<perlanet>

=item *

L<Plagger>

=back

=head1 AUTHOR

Dave Cross, <dave@mag-sol.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
