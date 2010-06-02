package Perlanet::Trait::Cache;
use Moose::Role;
use namespace::autoclean;

has 'cache'=> (
  is => 'rw'
);

around '_fetch_page' => sub {
  my $orig = shift;
  my ($self, $url) = @_;
  return URI::Fetch->fetch(
      $url,
      UserAgent     => $self->ua,
      Cache         => $self->cache || undef,
      ForceResponse => 1,
  );
};

1;
