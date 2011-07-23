use Test::More tests => 6;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'testrc'),
   'Object created');
isa_ok($p, 'Perlanet');

if (-e $p->opml) {
  unlink $p->opml;
}

if (-e $p->feed->{file}) {
  unlink $p->feed->{file};
}

if (-e $p->page->{file}) {
  unlink $p->page->{file};
}

$p->run;

ok(-e $p->feed->{file}, 'Feed created');
ok(-e $p->page->{file}, 'Page created');
SKIP: {
  skip 'XML::OPML::SimpleGen not installed', 1 unless $p->has_opml;
  ok(-e $p->opml, 'OPML created');
}

if (-e $p->opml) {
  unlink $p->opml;
}

if (-e $p->feed->{file}) {
  unlink $p->feed->{file};
}

if (-e $p->page->{file}) {
  unlink $p->page->{file};
}
