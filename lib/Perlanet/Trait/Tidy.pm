package Perlanet::Trait::Tidy;
use Moose::Role;
use namespace::autoclean;

use Encode;
use HTML::Tidy;

=head1 NAME

Perlanet::Trait::Tidy - run posts through HTML::Tidy

=head1 SYNOPSIS

  my $perlanet = Perlanet->new_with_traits(
    traits => [ 'Perlanet::Trait::Tidy' ]
  );

  $perlanet->run;

=head1 DESCRIPTION

Before a post is added to the aggregated feed, it will be ran through
HTML::Tidy.

=head2 Configuring

To configure the HTML::Tidy instance, you should override the C<_build_tidy>
method. This method takes no input, and returns a HTML::Tidy instance.

=head1 ATTRIBUTES

=head2 tidy

An instance of L<HTML::Tidy> used to tidy the feed entry contents
before outputting. For default settings see source..

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

=head1 AUTHOR

Oliver Charles, <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
