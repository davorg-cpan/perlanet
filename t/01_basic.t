use Test::More tests => 6;
use FindBin qw($Bin);
use_ok('Perlanet::Simple');
chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'testrc'),
   'Object created');
isa_ok($p, 'Perlanet');

if (-e $p->opml_file) {
  unlink $p->opml_file;
}

if (-e $p->feed_file) {
  unlink $p->feed_file;
}

if (-e $p->template_output) {
  unlink $p->cfg->{page}{file};
}

$p->run;

ok(-e $p->feed_file, 'Feed created');
ok(-e $p->template_output, 'Page created');
SKIP: {
  skip 'XML::OPML::SimpleGen not installed', 1 unless $p->opml_file;
  ok(-e $p->opml_file, 'OPML created');
}

if (-e $p->opml_file) {
  unlink $p->opml_file;
}

if (-e $p->feed_file) {
  unlink $p->feed_file;
}

if (-e $p->template_output) {
  unlink $p->template_output;
}
