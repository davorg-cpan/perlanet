use warnings;
use strict;

use Test::More;
use FindBin '$RealBin';
use YAML qw[LoadFile];
use Perlanet::Config;

my $yaml = LoadFile("$RealBin/perlanetrc");

my $config = Perlanet::Config->new($yaml);

ok($config);
isa_ok($config, 'Perlanet::Config');

done_testing();