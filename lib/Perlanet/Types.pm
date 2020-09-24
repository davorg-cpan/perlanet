package Perlanet::Types;

use Moose::Util::TypeConstraints;

use DateTime;
use DateTime::Duration;
use DateTime::Format::Strptime;

subtype 'Perlanet::DateTime',
  as 'DateTime';

subtype 'Perlanet::DateTime::Duration',
  as 'DateTime::Duration';

coerce 'Perlanet::DateTime',
  from 'Str',
  via {
    DateTime::Format::Strptime->new(
      pattern => '%Y-%m-%dT%H:%M%S',
    )->parse_datetime($_);
  };

coerce 'Perlanet::DateTime::Duration',
  from 'HashRef',
  via {
    DateTime::Duration->new($_);
  };

1;
