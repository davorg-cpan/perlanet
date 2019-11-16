use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use_ok('Perlanet::Simple');

chdir $Bin;
ok(my $p = Perlanet::Simple->new_with_config(configfile => 'testrc'),
   'Object created');
isa_ok($p,'Perlanet');

SKIP: {
  skip 'XML::OPML::SimpleGen not installed', 1 unless $p->has_opml;

  my (undef, $opml_file) = tempfile(OPEN => 0);
  $p->opml($opml_file);
  $p->run();
  $p->save_opml();
  ok(-e $opml_file, 'OPML file created');

  if (-e $p->opml) {
    unlink $p->opml;
  }

  if (-e $p->feed->{file}) {
    unlink $p->feed->{file};
  }

  if (-e $p->page->{file}) {
    unlink $p->page->{file};
  }
}

done_testing();
