package Perlanet::Simple;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Carp;
use YAML 'LoadFile';

extends 'Perlanet';
with qw(
    Perlanet::Trait::Cache
    Perlanet::Trait::OPML
    Perlanet::Trait::Scrubber
    Perlanet::Trait::Tidy
    Perlanet::Trait::YAMLConfig
    Perlanet::Trait::TemplateToolkit
    Perlanet::Trait::FeedFile
   );

=head1 NAME

Perlanet::Simple - a DWIM Perlanet

=head1 SYNOPSIS

    my $perlanet = Perlanet::Simple->new_with_config('perlanet.yaml')
    $perlanet->run

=head1 DESCRIPTION

L<Perlanet> provides the driving force behind all Perlanet applications,
but it doesn't do a whole lot, which means you would normally have to write
the functionality you require. However, in the motive of simplicity,
Perlanet::Simple glues enough stuff together to allow you to get a very quick
planet working out of the box.

Perlanet::Simple takes the standard Perlanet module, and adds support for
caching, OPML feed generation, and L<Template> rendering support. It will
also attempt to clean each post using both L<HTML::Scrubber> and L<HTML::Tidy>.

=head2 Configuration

Perlanet::Simple uses L<Perlanet::Trait::YAMLConfig> to allow you to specify
configuration through a file.

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

=item cache

An instance of L<CHI>. Optional. Defaults to a new instance with the
root_dir set to C<< $cfg->{cache_dir} >>, if it was supplied.

=cut

around '_build_ua' => sub {
  my $orig = shift;
  my $self = shift;
  my $ua = $self->$orig;
  $ua->agent($self->cfg->{agent}) if $self->cfg->{agent};
  return $ua;
};

=head2 clean_html

Some custom cleaning code to remove a nasty piece of BlogSpot HTML
(and still running all other cleaning traits)

=cut

around clean_html => sub {
  my $orig = shift;
  my ($self, $html) = @_;

  # hack to remove a particularly nasty piece of blogspot HTML
  $html = $self->$orig($html);who
  $html =~ s|<div align="justify"></div>||g;

  return $html;
};

1;
