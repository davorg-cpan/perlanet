use strict;
use warnings;
use Test::More;
use_ok('Perlanet');

# Test fetching a page without the cache trait.
ok(my $p = Perlanet->new(), 'Object created');
isa_ok($p, 'Perlanet');
ok(my $page = $p->fetch_page('http://blogs.dave.org.uk/rss.xml'),
   'Page fetched');
isa_ok($page, 'URI::Fetch::Response');

done_testing();
