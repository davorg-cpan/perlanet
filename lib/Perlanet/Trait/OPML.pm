package Perlanet::Trait::OPML;
use Moose::Role;
use namespace::autoclean;

use Carp qw( croak );
use POSIX qw(setlocale LC_ALL);

=head1 NAME

Perlanet::Trait::OPML - generate an OPML file

=head1 SYNOPSIS

   my $perlanet = Perlanet->new_with_traits( traits => [ 'Perlanet::Trait::OPML' ] )
   $perlanet->run

=head1 DESCRIPTION

Generates an OPML file of all feeds that are being aggregated by the planet.

=head1 ATTRIBUTES

=head2 opml_generator

An L<XML::OPML::SimpleGen> object to generate the XML for the OPML file

=cut

has 'opml_generator' => (
  is         => 'rw',
  isa        => 'XML::OPML::SimpleGen',
  lazy_build => 1
);

sub _build_opml_generator {
    my $self = shift;

    eval { require XML::OPML::SimpleGen; };

    if ($@) {
        croak 'You need to install XML::OPML::SimpleGen to enable OPML ' .
            'support';
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
  isa       => 'Str',
  is        => 'rw',
  predicate => 'has_opml_file'
);

=head1 METHODS

=head2 update_opml

Updates the OPML file of all contributers to this planet. If the L<opml>
attribute does not have a value, this method does nothing, otherwise it inserts
each author into the OPML file and saves it to disk.

=cut

sub update_opml {
  my ($self, @feeds) = @_;

  foreach my $f (@feeds) {
      $self->opml_generator->insert_outline(
          title   => $f->title,
          text    => $f->title,
          xmlUrl  => $f->url,
          htmlUrl => $f->url,
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
    my ($self, @feeds) = @_;
    return unless $self->has_opml_file;
    @feeds = $self->$orig(@feeds);
    $self->update_opml(@feeds);
    return @feeds;
};

=head1 AUTHOR

Dave Cross, <dave@mag-sol.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
