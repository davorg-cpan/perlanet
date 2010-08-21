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
  $perlanet->run;

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

=cut

around '_build_ua' => sub {
  my $orig = shift;
  my $self = shift;
  my $ua = $self->$orig;
  $ua->agent($self->agent) if $self->agent;
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
  $html = $self->$orig($html);
  $html =~ s|<div align="justify"></div>||g;

  return $html;
};

1;
