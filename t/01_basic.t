use Test::More tests => 3;
use_ok('Perlanet');
ok(my $p = Perlanet->new('testrc'));
isa_ok($p, 'Perlanet');
