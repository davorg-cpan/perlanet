use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'spamrc'),
   'Object created');
isa_ok($p, 'Perlanet');

my $feeds = $p->fetch_feeds($p->feeds);
my $selected = $p->select_entries($feeds);
is(@$selected, 10, 'Ten selected entries');

for (@$selected) {
  fail('Austr.*ian filter failed') if $_->title =~ /Austr.*ian/;
  fail('Winston filter failed')    if $_->title =~ /Winston/;
}

done_testing();
