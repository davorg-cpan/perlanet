package Perlanet::Trait::OPML;
use Moose::Role;
use namespace::autoclean;

has 'opml' => (
  is  => 'rw',
  isa => 'XML::OPML::SimpleGen'
);

=head2 update_opml

Updates the OPML file of all contributers to this planet. If the L<opml>
attribute does not have a value, this method does nothing, otherwise it inserts
each author into the OPML file and saves it to disk.

Uses the list of feeds from the L<perlanet/CONFIGURATION>.

=cut

sub update_opml {
  my $self = shift;

  return unless $self->opml;

  foreach my $f (@{$self->cfg->{feeds}}) {
    if ($self->opml) {
      $self->opml->insert_outline(
        title   => $f->{title},
        text    => $f->{title},
        xmlUrl  => $f->{url},
        htmlUrl => $f->{web},
      );
    }
  }

  $self->opml->save($self->cfg->{opml});

  return;
}

before 'run' => sub {
    my $self = shift;
    $self->update_opml;
};

1;
