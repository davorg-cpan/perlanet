package Perlanet::Trait::Cache;
use Moose::Role;
use namespace::autoclean;

=head1 NAME

Perlanet::Trait::Cache - cache feeds with CHI

=head1 SYNOPSIS

   my $perlanet = Perlanet->new_with_traits( traits => [ 'Perlanet::Trait::Cache' ] )
   $perlanet->run

=head1 DESCRIPTION

Everytime a page is fetched it is cached first through CHI. This allows you to cache
pages to a local disk for example, if the feed has not changed.

=head1 ATTRIBUTES

=head2 cache

The L<Chi> cache object

=cut

has 'cache'=> (
  is => 'rw'
);

around 'fetch_page' => sub {
  my $orig = shift;
  my ($self, $url) = @_;
  return URI::Fetch->fetch(
      $url,
      UserAgent     => $self->ua,
      Cache         => $self->cache || undef,
      ForceResponse => 1,
  );
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
