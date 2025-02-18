package Perlanet::Trait::Tidy;

use 5.10.0;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

use Encode;
use HTML::T5;

=head1 NAME

Perlanet::Trait::Tidy - run posts through HTML::T5 (an HTML::Tidy replacement)

=head1 SYNOPSIS

  my $perlanet = Perlanet->new_with_traits(
    traits => [ 'Perlanet::Trait::Tidy' ]
  );

  $perlanet->run;

=head1 DESCRIPTION

Before a post is added to the aggregated feed, it will be run through
HTML::T5.

=head2 Configuring

To configure the HTML::T5 instance, you should override the C<_build_tidy>
method. This method takes no input, and returns a HTML::T5 instance.

=head1 ATTRIBUTES

=head2 tidy

An instance of L<HTML::T5> used to tidy the feed entry contents
before outputting. For default settings see source..

=cut

has 'tidy' => (
  is         => 'ro',
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

  my $tidy = HTML::T5->new(\%tidy);
  $tidy->ignore( type => TIDY_WARNING );

  return $tidy;
}

around 'clean_html' => sub {
  my $orig = shift;
  my $self = shift;
  my ($html) = @_;

  warn __PACKAGE__, '::clean_html' if $ENV{PERLANET_DEBUG};

  $html = $self->$orig($html);

  my $clean = $self->tidy->clean(utf8::is_utf8($html)
    ? $html
    : decode('utf8', $html));

  return $clean;
};

=head1 AUTHOR

Oliver Charles, <oliver.g.charles@googlemail.com>
Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2023 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
