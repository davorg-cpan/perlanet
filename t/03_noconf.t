use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Perlanet::Simple;

chdir $Bin;
my $p = eval { Perlanet::Simple->new_with_config(configfile => 'missing') };

ok($@, 'Exception thrown');
like($@, qr(^Cannot open), 'Correct exception thrown');

done_testing();
