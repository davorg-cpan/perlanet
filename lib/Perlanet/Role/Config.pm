package Perlanet::Role::Config;

use 5.10.0;
use strict;
use warnings;

use Moose::Role;

use constant THIRTY_DAYS => 30 * 24 * 60 * 60;

=head1 NAME

Perlanet::Role::Config - A role to be used in Perlanet traits that read config.

=head1 SYNOPSIS

   package Perlanet::Trait::MyConfig;

   use Moose::Role;

   with 'Perlanet::Role::Config';

  # Class method to return the config
  sub get_config_from_somewhere {
    my $class = shift;

    # get_config() is defined in this role
    return $class->get_config(@_)
  }

  # get_config() calls this to actually read the config.
  sub read_config {
    my $class = shift;
    my %params = @_;

    my $cfg = ...;

    return $cfg;
  }

=head1 DESCRIPTION

A role that is used to build Perlanet traits which read config information
from various sources.

This role does two things:

=over 4

=item *

It exposes a method called C<get_config()> which gets the raw config data
(using your C<read_config()> method).

=item *

It forces your trait to define a method called C<read_config()> which actually
reads the config and returns it as a hash reference.

=back

=head2 METHODS

=head3 get_config

Calls your C<read_config()> method to actually get the config data (as a hash
reference) and then munges that data in various ways to get a useful config
hash.

=cut

sub get_config {
  my $class = shift;
  my (%params) = @_;
 
  my $cfg = $class->read_config(%params);
 
  $cfg->{config} = $cfg;

  $cfg->{feeds} = [ map {
    Perlanet::Feed->new($_)
  } @{ $cfg->{feeds} } ];
 
  $cfg->{max_entries} = $cfg->{entries}
    if $cfg->{entries};
 
  if ($cfg->{cache_dir}) {
    eval { require CHI; };
 
    if ($@) {
      warn "You need to install CHI to enable caching.\n",
           "Caching disabled for this run.\n";
      delete $cfg->{cache_dir};
    }
  }
 
  $cfg->{cache_dir}
    and $cfg->{cache} = CHI->new(
      driver     => 'File',
      root_dir   => delete $cfg->{cache_dir},
      expires_in => THIRTY_DAYS,
    );
 
  return $cfg;
}

=head3 THIRTY_DAYS

Constant to define the default cache expiration time in seconds.

=head1 AUTHOR

Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
