use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use YAML 'LoadFile';

use_ok('Perlanet::Simple');

chdir $Bin;

my $cfg = LoadFile('testrc');
$cfg->{feeds} = [ map { Perlanet::Feed->new($_) } @{ $cfg->{feeds} } ];

my (undef, $opml_file) = tempfile(OPEN => 0);

$cfg->{opml_file} = $opml_file;
$cfg->{config} = $cfg;

ok(my $p = Perlanet::Simple->new($cfg),
   'Object created');
isa_ok($p,'Perlanet');

SKIP: {
  skip 'XML::OPML::SimpleGen not installed', 1 unless $p->has_opml;

  # $p->opml_file($opml_file);
  $p->run();
  $p->save_opml();
  ok(-e $opml_file, 'OPML file created');

  if (-e $p->opml_file) {
    unlink $p->opml_file;
  }

  if (-e $p->feed->{file}) {
    unlink $p->feed->{file};
  }

  if (-e $p->page->{file}) {
    unlink $p->page->{file};
  }
}

done_testing();
