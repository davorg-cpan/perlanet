package Perlanet::Role::Config;

use strict;
use warnings;

use Moose::Role;
use Carp;

sub get_config {
  my $class = shift;
  my (%params) = @_;
 
  my $cfg = $class->read_config(%params);
 
  $cfg->{feeds} = [ map {
    Perlanet::Feed->new($_)
  } @{ $cfg->{feeds} } ];
 
  $cfg->{max_entries} = $cfg->{entries}
    if $cfg->{entries};
 
  if ($cfg->{cache_dir}) {
    eval { require CHI; };
 
    if ($@) {
      carp "You need to install CHI to enable caching.\n";
      carp "Caching disabled for this run.\n";
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

1;
