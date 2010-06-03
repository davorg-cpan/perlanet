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
  $VERSION = '0.46';
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

has 'max_entries' => (
    isa => 'Int',
    is  => 'rw',
    predicate => 'has_max_entry_cap'
);

has 'feeds' => (
  isa        => 'ArrayRef',
  is         => 'ro',
);

has $_ => (
    isa => 'Str',
    is  => 'ro',
) for qw( self_link title description url author_name author_email );

=head1 NAME

Perlanet - A program for creating web pages that aggregate web feeds (both
RSS and Atom).

=head1 SYNOPSIS

  my $perlanet = Perlanet->new;
  $perlanet->run;

=head1 DESCRIPTION

Perlanet is a program for creating web pages that aggregate web feeds (both
RSS and Atom). Web pages like this are often called "Planets" after the Python
software which originally popularised them. Perlanet is a planet builder
written in Perl - hence "Perlanet".

The emphasis on Perlanet is firmly on simplicity. It reads web feeds, merges
them and publishes the merged feed as a web page and as a new feed. That's all
it is intended to do. If you want to do more with your feeds (create feeds
from inputs that don't publish feeds, filter or transform them in complex ways
or publish them in interesting ways) then Perlanet isn't the right software
for you. In that case I recommend that you take a look at Plagger - which is
another feed aggregator, but one that is far more complex and, therefore, far
more flexible.

For most uses, you probably don't want to use the Perlanet module. The
L<perlanet> command line program is far more likely to be useful.

=head1 CONSTRUCTOR

=head2 new

  my $perlanet = Perlanet->new([ $config_filename ]);

The constructor method. Can be passed the filename of a configuration
file (default C<./perlanetrc>) or a hashref of initialisers.

=head3 Example Configuration File

  title: planet test
  description: A Test Planet
  url: http://planet.example.com/
  author:
    name: Dave Cross
    email: dave@dave.org.uk
  entries: 20
  opml: opml.xml
  page:
    file: index.html
    template: index.tt
  feed:
    file: atom.xml
    format: Atom
  cache_dir: /tmp/feeds
  feeds:
    - url: http://blog.dave.org.uk/atom.xml
      title: Dave's Blog
      web: http://blog.dave.org.uk/
    - url: http://use.perl.org/~davorg/journal/rss
      title: Dave's use.perl Journal
      web: http://use.perl.org/~davorg/journal/
    - url: http://www.oreillynet.com/pub/feed/31?au=2607
      title: Dave on O'Reillynet
      web: http://www.oreillynet.com/pub/au/2607

For a detailed explanation of the configuration file contents, see
L<perlanet/CONFIGURATION FILE>.

=head3 Customised use (advanced)

  my $perlanet = Perlanet->new(\%custom_attr_values);

Perlanet is a L<Moose> class, if the configuration file doesn't
provide enough flexibility, you may also instantiate the attribute
values directly.

See L</ATTRIBUTES> below for details of the key/value pairs to pass in.

=head1 ATTRIBUTES

=over

=item cfg

A hashref of configuration data. This is filled from the configuration
file if supplied. Use this if you want an alternative to the YAML
format of the file.

=item ua

An instance of L<LWP::UserAgent>. Defaults to a simple agent using C<<
$cfg->{agent} >> as the user agent name, or C< Perlanet/$VERSION >.

=item opml

An instance of L<XML::OPML::SimpleGen>. Optional. Defaults to a new
instance with C<< $cfg->{title} >> as it's title.

=item cache

An instance of L<CHI>. Optional. Defaults to a new instance with the
root_dir set to C<< $cfg->{cache_dir} >>, if it was supplied.

=item cutoff

An instance of L<DateTime> which represents the earliest date for
which feed posts will be fetched/shown.

=item feeds

An arrayref of L<Perlanet::Feed> objects representing the feeds to
collect data from.

=item tidy

An instance of L<HTML::Tidy> used to tidy the feed entry contents
before outputting. For default settings see source of Perlanet.pm.

=item scrubber

An instance of L<HTML::Scrubber> used to remove unwanted content from
the feed entries. For default settings see source of Perlanet.pm.

=back

=head1 METHODS

=head2 fetch_feeds

Called internally by L</run> and passed the list of feeds in L</feeds>.

Attempt to download all given feeds, as specified in the C<feeds> attribute. Returns a list of
L<Perlanet::Feed> objects, with the actual feed data loaded.

NB: This method also modifies the contents of L</feeds>.

=cut

sub _fetch_page {
  my ($self, $url) = @_;
  return URI::Fetch->fetch(
      $url,
      UserAgent     => $self->ua,
      ForceResponse => 1,
  );
}

sub fetch_feeds {
  my ($self, @feeds) = @_;

  my @valid_feeds;
  for my $feed (@feeds) {
    my $response = $self->_fetch_page($feed->url);

    next if $response->is_error;

    try {
      my $data = $response->content;
      my $xml_feed = XML::Feed->parse(\$data);

      $feed->_xml_feed($xml_feed);
      $feed->title($xml_feed->title) unless $feed->title;

      push @valid_feeds, $feed;
    }
      catch {
        carp 'Errors parsing ' . $feed->url;
      }
    }

  return @valid_feeds;
}

=head2 select_entries

Called internally by L</run> and passed the list of feeds from L</fetch_eeds>.

Returns a combined list of L<Perlanet::Entry> objects from all given feeds.

=begin comment

## why isnt this the case?

The returned list has been filtered according to any filters set up in the L<perlanet/CONFIGURATION>.

=end comment

=cut

sub select_entries {
  my ($self, @feeds) = @_;

  my @feed_entries;
  for my $feed (@feeds) {
    my @entries = $feed->_xml_feed->entries;

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

Called internally by L</run> and passed the list of entries from L</select_entries>.

Sort the given list of entries into created/modified order for aggregation. Takes a list of
L<Perlanet::Entry>s, and returns an ordered list.

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
  if ($self->has_max_entry_cap && @entries > $self->max_entries) {
    $#entries = $self->max_entries - 1;
  }

  return @entries;
}

=head2 clean

Clean a content string into a form presentable for display. By default, this
means running the content through both HTML::Tidy and HTML::Scrubber. These 2
modules are configurable by override the L</tidy> and L</scrubber> attributes. If
you do not wish to use HTML::Tidy/HTML::Scrubber or do something more complex,
you may override this method.

Takes a string, and returns the cleaned string.

=cut

sub clean {
  my ($self, $entry) = @_;
  return $entry;
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

  my $f = Perlanet::Feed->new(
    title       => $self->title,
    url         => $self->url,
    description => $self->description,
    author      => $self->author_name,
    email       => $self->author_email,
    modified    => DateTime->now,
    self_link   => $self_url,
    id          => $self_url
  );

  $f->add_entry($_) for @entries;

  return $f;
}

sub clean_entries
{
    my ($self, @entries) = @_;
    return map { $self->clean($_) } @entries;
}

=head2 render

Called internally by L</run> and passed the feed from L</build_feed>.

Render the planet feed as a page. By default, this uses L<Template>
Toolkit to render to an HTML file, but can be overriden to render to
wherever you need.

Takes a L<Perlanet::Feed> as input (as generated by L<build_feed>, the
result is output to the configured C<< $cfg->[page}{file> >>.

=cut

sub render {
  my ($self, $feed) = @_;
}

=head2 run

The main method which runs the perlanet process.

=cut

sub run {
  my $self = shift;

  $self->render(
      $self->build_feed(
          $self->clean_entries(
              $self->sort_entries(
                  $self->select_entries(
                      $self->fetch_feeds(@{ $self->feeds }))))));
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

Copyright (C) 2008 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
