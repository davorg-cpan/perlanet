use Test::More tests => 9;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'testrc'),
   'Object created');
isa_ok($p, 'Perlanet');

is(@{$p->feeds}, 1, 'One feed');
my @feeds = $p->fetch_feeds(@{$p->feeds});
is(@feeds, 1, 'One fetchable feed');
my @selected = $p->select_entries(@feeds);
is(@selected, 1, 'One selected entry');
my @sorted = $p->sort_entries(@selected);
is(@sorted, 1, 'One sorted entry');
my @cleaned = $p->clean_entries(@sorted);
is(@cleaned, 1, 'One cleaned entry');
my $feed = $p->build_feed(@cleaned);
isa_ok($feed, 'Perlanet::Feed', 'Got a feed');

