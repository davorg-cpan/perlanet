use Test::More tests => 1;
use FindBin qw($Bin);
use File::Path;
use Perlanet;
chdir $Bin;

eval { require CHI; };

SKIP: {
  skip 'CHI required for caching test', 1 if $@;

  chdir($Bin);

  my $p = Perlanet->new('cacherc');

  rmtree($p->cfg->{cache_dir});

  my @entries = $p->select_entries(
                  $p->fetch_feeds(
                    @{$p->feeds},
                  ),
                );
  my $first_count = scalar @entries;

  @entries = $p->select_entries(
               $p->fetch_feeds(
                 @{$p->feeds},
               ),
             );

  my $second_count = scalar @entries;

  # count should be the same on a second attempt
  is($first_count, $second_count, "$first_count == $second_count");

  rmtree($p->cfg->{cache_dir});
}

