use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);

use lib qw( ../lib );
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'testrc'),
   'Object created');
isa_ok($p, 'Perlanet');

if (-e $p->opml_file) {
  unlink $p->opml_file;
}

if (-e $p->feed->{file}) {
  unlink $p->feed->{file};
}

if (-e $p->page->{file}) {
  unlink $p->page->{file};
}

is($p->config->{google_ga}, 'HELLO_GOOGLE', 'Config is correct');

$p->run;

ok(-e $p->feed->{file}, 'Feed created');
ok(-e $p->page->{file}, 'Page created');
SKIP: {
  skip 'XML::OPML::SimpleGen not installed', 1 unless $p->has_opml;
  ok(-e $p->opml_file, 'OPML created');
}

if (-e $p->opml_file) {
  unlink $p->opml_file;
}

if (-e $p->feed->{file}) {
  unlink $p->feed->{file};
}

if (-e $p->page->{file}) {
  unlink $p->page->{file};
}

done_testing();
