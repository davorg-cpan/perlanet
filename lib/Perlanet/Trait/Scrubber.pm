package Perlanet::Trait::Scrubber;

use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

use HTML::Scrubber;

=head1 NAME

Perlanet::Trait::Scrubber - clean posts with HTML::Scrubber before aggregating

=head1 DESCRIPTION

Before adding a post to the aggregated feed, it will first be cleaned with
L<HTML::Scrubber>.

=head1 ATTRIBUTES

=head1 scrubber

An instance of L<HTML::Scrubber> used to remove unwanted content from
the feed entries. For default settings see source of Perlanet.pm.

=cut

has 'scrubber' => (
  is         => 'rw',
  lazy_build => 1
);

sub _build_scrubber {
  my $self = shift;

  my %scrub_rules = (
    img => {
      src   => qr{^http://},    # only URL with http://
      alt   => 1,               # alt attributes allowed
      align => 1,               # allow align on images
      style => 1,
      '*'   => 0,               # deny all others
    },
    style => 0,
    script => 0,
    span => {
      id => 0,                  # blogger(?) includes spans with id attribute
    },
    a => {
      href => 1,
      '*'  => 0,
    },
  );

  # Definitions for HTML::Scrub
  my %scrub_def = (
    '*'           => 1,
    'href'        => qr{^(?!(?:java)?script)}i,
    'src'         => qr{^(?!(?:java)?script)}i,
    'cite'        => '(?i-xsm:^(?!(?:java)?script))',
    'language'    => 0,
    'name'        => 1,
    'value'       => 1,
    'onblur'      => 0,
    'onchange'    => 0,
    'onclick'     => 0,
    'ondblclick'  => 0,
    'onerror'     => 0,
    'onfocus'     => 0,
    'onkeydown'   => 0,
    'onkeypress'  => 0,
    'onkeyup'     => 0,
    'onload'      => 0,
    'onmousedown' => 0,
    'onmousemove' => 0,
    'onmouseout'  => 0,
    'onmouseover' => 0,
    'onmouseup'   => 0,
    'onreset'     => 0,
    'onselect'    => 0,
    'onsubmit'    => 0,
    'onunload'    => 0,
    'src'         => 1,
    'type'        => 1,
    'style'       => 1,
    'class'       => 0,
    'id'          => 0,
  );

  my $scrub = HTML::Scrubber->new;
  $scrub->rules(%scrub_rules);
  $scrub->default(1, \%scrub_def);

  return $scrub;
}

around 'clean_html' => sub {
  my $orig = shift;
  my ($self, $html) = @_;
  $html = $self->$orig($html);
  my $scrubbed = $self->scrubber->scrub($html);
  return $html;
};

=head1 AUTHOR

Dave Cross, <dave@mag-sol.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
