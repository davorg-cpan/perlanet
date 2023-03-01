package Perlanet::Trait::YAMLConfig;

use 5.10.0;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

Perlanet::Trait::YAMLConfig - configure Perlanet through a YAML configuration
file

=head1 SYNOPSIS

   package MyPerlanet;
   extends 'Perlanet';
   with 'Perlanet::Traits::YAMLConfig';

   my $perlanet = MyPerlanet->new_with_config(
     configfile => 'whatever.yml'
   );

   $perlanet->run;

=head1 DESCRIPTION

Allows you to move the configuration of Perlanet to an external YAML
configuration file.

=head2 Example Configuration File

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
    - feed: http://blog.dave.org.uk/atom.xml
      title: Dave's Blog
      web: http://blog.dave.org.uk/
    - feed: http://use.perl.org/~davorg/journal/rss
      title: Dave's use.perl Journal
      web: http://use.perl.org/~davorg/journal/
    - feed: http://www.oreillynet.com/pub/feed/31?au=2607
      title: Dave on O'Reillynet
      web: http://www.oreillynet.com/pub/au/2607

=head1 METHODS

=head2 get_config_from_file

Extracts the configuration from a YAML file

=cut

with 'MooseX::ConfigFromFile', 'Perlanet::Role::Config';

use Carp qw( carp croak );
use YAML qw( LoadFile );

sub get_config_from_file {
  my $class = shift;
  return $class->get_config(config_file => $_[0]);
}

=head2 read_config

Actually reads the YAML.

=cut

sub read_config {
  my $class = shift;
  my (%params) = @_;

  my $file = $params{config_file}
    // croak "No config file passed to read_config().";

  open my $cfg_file, '<:encoding(UTF-8)', $file
    or croak "Cannot open file $file: $!";

  my $cfg = LoadFile($cfg_file);

  return $cfg;
}

=head1 AUTHOR

Oliver Charles, <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
