use strict;
use warnings;
use Test::More;
use_ok('Perlanet');

# Test fetching a page without the cache trait.
ok(my $p = Perlanet->new(), 'Object created');
isa_ok($p, 'Perlanet');
ok(my $response = $p->fetch_feed('https://blog.dave.org.uk/rss.xml'),
   'Feed fetched');
isa_ok($response, 'URI::Fetch::Response');

done_testing();
