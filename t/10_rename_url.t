use strict;
use warnings;

use Test::More;
use Test::Warnings 'warning';
use FindBin qw($Bin);

use lib qw( ../lib );
use_ok('Perlanet::Simple');

chdir $Bin;
my $p;

my $warning = warning {
  $p = Perlanet::Simple->new_with_config(configfile => 'oldurlrc')
};

like $warning, qr[^Your config file uses],
     'Correct warning on parsing config';

$warning = warning {
  $p->feeds->[0]->url
};

like $warning, qr[^The url\(\) method has been renamed],
     'Correct warning on calling method';

done_testing();
