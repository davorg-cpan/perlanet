package Perlanet::Trait::TemplateToolkit;

use 5.10.0;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

Perlanet::Trait::TemplateToolkit - render the feed via a Template Toolkit
template

=head1 SYNOPSIS

   my $perlanet = Perlanet->new_with_traits(
     traits => [ 'Perlanet::Trait::TemplateToolkit' ]
   );

   $perlanet->run;

=head1 DESCRIPTION

Renders the aggregated set of feeds via a Template Toolkit template.

=head1 ATTRIBUTES

=head2 template_input

The Template Toolkit template to use as input

=head2 template_output

The path to save the resulting output to

=head1 TEMPLATE TOOLKIT STASH

The following are exported into your template:

=head2 feed

A L<Perlanet::Feed> that represents the aggregation of all posts

=cut

use Template;
use Carp;

has 'page' => (
  isa       => 'HashRef',
  is        => 'rw',
  default   => sub {
    { file => 'index.html', template => 'index.tt' };
  },
);

after 'render' => sub {
  my $self = shift;
  my ($feed) = @_;
  my $tt = Template->new;
  $tt->process(
    $self->page->{template},
    {
      feed   => $feed,
      cfg    => $self, # deprecated
      config => $self->config,
    },
    $self->page->{file},
    {
      binmode => ':utf8'
    }
  ) or croak $tt->error;
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
