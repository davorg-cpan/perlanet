package Perlanet::Trait::FeedFile;
use Moose::Role;
use namespace::autoclean;

=head1 NAME

Perlanet::Trait::FeedFile - save the aggregated feed to a file

=head1 SYNOPSIS

   my $perlanet = Perlanet->new_with_traits(
     traits => [ 'Perlanet::Trait::FeedFile' ]
   );

   $perlanet->run;

=head1 DESCRIPTION

When the aggregation is complete and the feed is being rendered, it will be
saved to disk in XML format.

=head1 ATTRIBUTES

=head2 feed_file

The path to the file to save the feed to.

=head2 feed_format

The format of the XML to use - may be RSS or Atom

=cut

use Carp qw( croak );
use Template;

has 'feed' => (
  isa       => 'HashRef',
  is        => 'rw',
  default   => sub {
    { file => 'atom.xml', format => 'Atom' }
  },
);

after 'render' => sub {
  my ($self, $feed) = @_;
  return unless $self->feed->{file};

  open my $feedfile, '>', $self->feed->{file}
    or croak 'Cannot open ' . $self->feed->{file} . " for writing: $!";
  print $feedfile $feed->as_xml($self->feed->{format});
  close $feedfile;
};

=head1 AUTHOR

Oliver Charles, <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
