package Perlanet::Trait::OPML;

use 5.10.0;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

use POSIX qw(setlocale LC_ALL);

=head1 NAME

Perlanet::Trait::OPML - generate an OPML file

=head1 SYNOPSIS

  my $perlanet = Perlanet->new_with_traits(
    traits => [ 'Perlanet::Trait::OPML' ]
  );

  $perlanet->run;

=head1 DESCRIPTION

Generates an OPML file of all feeds that are being aggregated by the planet.

=head1 ATTRIBUTES

=head2 opml_generator

An L<XML::OPML::SimpleGen> object to generate the XML for the OPML file

=cut

has 'opml_generator' => (
  is         => 'ro',
  isa        => 'Maybe[XML::OPML::SimpleGen]',
  builder    => '_build_opml_generator',
  predicate  => 'has_opml',
  required   => 1,
);

sub _build_opml_generator {
  my $self = shift;

  eval { require XML::OPML::SimpleGen; };

  if ($@) {
    warn 'You need to install XML::OPML::SimpleGen to enable OPML ' .
          "support\n";
    $self->opml_file(undef);
    return;
  }

  my $loc = setlocale(LC_ALL, 'C');
  my $opml = XML::OPML::SimpleGen->new;
  setlocale(LC_ALL, $loc);
  $opml->head(
    title => $self->title,
  );

  return $opml;
}


=head2 opml_file

Where to save the OPML feed when it has been created

=cut

has 'opml_file' => (
  isa       => 'Maybe[Str]',
  is        => 'ro',
);

=head1 METHODS

=head2 update_opml

Updates the OPML file of all contributors to this planet. If the L<opml_file>
attribute does not have a value, this method does nothing, otherwise it inserts
each author into the OPML file and saves it to disk.

=cut

sub update_opml {
  my $self = shift;
  my ($feeds) = @_;

  foreach my $f (@$feeds) {

    return unless $self->opml_file and $self->has_opml;

    $self->opml_generator->insert_outline(
      title   => $f->title,
      text    => $f->title,
      xmlUrl  => $f->feed,
      htmlUrl => $f->feed,
    );
  }

  $self->save_opml;
}

=head2 save_opml

Save the OPML file, by default to disk.

=cut

sub save_opml {
  my $self = shift;
  $self->opml_generator->save($self->opml_file);
}

around 'fetch_feeds' => sub {
  my $orig = shift;
  my $self = shift;
  my ($feeds) = @_;
  $feeds = $self->$orig($feeds);
  $self->update_opml($feeds) if $self->has_opml;
  return $feeds;
};

=head1 AUTHOR

Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
