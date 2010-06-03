package Perlanet::Trait::Tidy;
use Moose::Role;
use namespace::autoclean;

use Encode;
use HTML::Tidy;

=head1 ATTRIBUTES

=head2 tidy

An instance of L<HTML::Tidy> used to tidy the feed entry contents
before outputting. For default settings see source of Perlanet.pm.

=cut

has 'tidy' => (
  is         => 'rw',
  lazy_build => 1
);

sub _build_tidy {
  my $self = shift;
  my %tidy = (
    doctype           => 'omit',
    output_xhtml      => 1,
    wrap              => 0,
    alt_text          => '',
    break_before_br   => 0,
    char_encoding     => 'raw',
    tidy_mark         => 0,
    show_body_only    => 1,
    preserve_entities => 1,
    show_warnings     => 0,
  );

  my $tidy = HTML::Tidy->new(\%tidy);
  $tidy->ignore( type => TIDY_WARNING );

  return $tidy;
}

around 'clean_html' => sub {
    my $orig = shift;
    my ($self, $html) = @_;
    $html = $self->$orig($html);

    my $clean = $self->tidy->clean(utf8::is_utf8($html)
      ? $html
        : decode('utf8', $html));

    return $clean;
};

1;
