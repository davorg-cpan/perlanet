use Test::More tests => 3;
use FindBin qw($Bin);
use_ok('Perlanet');
ok(my $p = Perlanet->new($Bin .'/testrc'));
isa_ok($p, 'Perlanet');
$p->run;
