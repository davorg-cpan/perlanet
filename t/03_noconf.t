use Test::More tests => 2;
use FindBin qw($Bin);
use Perlanet;

chdir $Bin;
my $p = eval { Perlanet->new('missing') };

ok($@, 'Exception thrown');
like($@, qr(^Cannot open), 'Correct exception thrown');
