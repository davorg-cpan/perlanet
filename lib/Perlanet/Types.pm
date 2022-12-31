=head1 NAME

Perlanet::Types - Various types for the Perlanet system.

=head1 SYNOPSIS

    # n/a

=head1 DESCRIPTION

This class acts as a repository of types used at various places in
Perlanet.

=cut

package Perlanet::Types;

use 5.10.0;
use strict;
use warnings;

use Moose::Util::TypeConstraints;

use DateTime;
use DateTime::Duration;
use DateTime::Format::Strptime;

=head1 TYPES

=head2 Perlanet::DateTime

Our subclass of DateTime (along with a coercion to automatically create
it from a string).

=cut

subtype 'Perlanet::DateTime',
  as 'DateTime';

coerce 'Perlanet::DateTime',
  from 'Str',
  via {
    DateTime::Format::Strptime->new(
      pattern => '%Y-%m-%dT%H:%M%S',
    )->parse_datetime($_);
  };

=head2 Perlanet::DateTime::Duration

Our subtype of DateTime::Duration (along with a coercion to automatically
create it from a hash reference).

=cut

subtype 'Perlanet::DateTime::Duration',
  as 'DateTime::Duration';

coerce 'Perlanet::DateTime::Duration',
  from 'HashRef',
  via {
    DateTime::Duration->new($_);
  };

=head1 AUTHOR

Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
