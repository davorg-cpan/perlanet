use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Perlanet::Simple;

chdir $Bin;

my @tests = ({
  rc    => '5',
  count =>  5,
}, {
  rc    => 'all',
  count => 10,
});

for (@tests) {
  my $p = Perlanet::Simple->new_with_config(configfile => "$_->{rc}entriesrc");

  my $feeds = $p->fetch_feeds($p->feeds);
  my $selected = $p->select_entries($feeds);
  is(@$selected, $_->{count}, "Override to get $_->{rc} selected entries");
}

done_testing();
