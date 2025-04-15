use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'mprc'),
   'Object created');
isa_ok($p, 'Perlanet');

is(@{$p->feeds}, 2, 'Two feeds');

is($p->feeds->[0]->slug, 'con-wycombe-steve-baker', 'Slug 1 is correct');
is($p->feeds->[1]->slug, 'con-clacton-douglas-carswell', 'Slug 2 is correct');

my $feeds = $p->fetch_feeds($p->feeds);
is(@$feeds, 2, 'Two fetchable feeds');
my $selected = $p->select_entries($feeds);
is(@$selected, 2, 'Two selected entries');
my $sorted = $p->sort_entries($selected);
is(@$sorted, 2, 'Two sorted entries');
my $cleaned = $p->clean_entries($sorted);
is(@$cleaned, 2, 'Two cleaned entries');
my $feed = $p->build_feed($cleaned);
isa_ok($feed, 'Perlanet::Feed', 'Got a feed');

done_testing();
