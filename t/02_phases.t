use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(
  configfile => 'testrc_no_opml',
),
   'Object created');
isa_ok($p, 'Perlanet');

is(@{$p->feeds}, 1, 'One feed');
my $feeds = $p->fetch_feeds($p->feeds);
is(@$feeds, 1, 'One fetchable feed');
my $selected = $p->select_entries($feeds);
is(@$selected, 1, 'One selected entry');
my $sorted = $p->sort_entries($selected);
is(@$sorted, 1, 'One sorted entry');
my $cleaned = $p->clean_entries($sorted);
is(@$cleaned, 1, 'One cleaned entry');
my $feed = $p->build_feed($cleaned);
isa_ok($feed, 'Perlanet::Feed', 'Got a feed');

{
    no warnings qw( redefine once );
    local *XML::Feed::parse = sub { die "Can't parse\n" };
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, @_;
    };
    $p->fetch_feeds($p->feeds);

    is(scalar @warnings, 2, 'Two warnings');
    like($warnings[0], qr/Errors parsing/, 'Warning from Perlanet');
    like($warnings[1], qr/Can't parse/, 'Original exception');
}

done_testing();
