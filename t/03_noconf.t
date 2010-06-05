use Test::More tests => 2;
use FindBin qw($Bin);
use Perlanet::Simple;

chdir $Bin;
my $p = eval { Perlanet::Simple->new_with_config(configfile => 'missing') };

ok($@, 'Exception thrown');
like($@, qr(^Cannot open), 'Correct exception thrown');
