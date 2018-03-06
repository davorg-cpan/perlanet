use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Perlanet::Simple;

chdir $Bin;
my $p = Perlanet::Simple->new_with_config(configfile => 'youtuberc');

my $feeds = $p->fetch_feeds($p->feeds);
my $selected = $p->select_entries($feeds);
my $sorted = $p->sort_entries($selected);

is($sorted->[0]->issued->ymd,   '2016-12-08', 'First item sorted correctly');
is($sorted->[0]->modified->ymd, '2017-06-30', 'First item sorted correctly');
is($sorted->[4]->issued->ymd,   '2016-02-19', 'Last item sorted correctly');
is($sorted->[4]->modified->ymd, '2017-07-01', 'Last item sorted correctly');

$p = Perlanet::Simple->new_with_config(configfile => 'youtube2rc');

$feeds = $p->fetch_feeds($p->feeds);
$selected = $p->select_entries($feeds);
$sorted = $p->sort_entries($selected);

is($sorted->[0]->issued->ymd, '2015-04-10', 'First item sorted correctly');
is($sorted->[0]->modified->ymd, '2017-07-02', 'First item sorted correctly');
is($sorted->[4]->issued->ymd, '2015-04-10', 'Last item sorted correctly');
is($sorted->[4]->modified->ymd, '2017-06-27', 'Last item sorted correctly');

done_testing;
