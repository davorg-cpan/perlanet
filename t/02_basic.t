use Test::More tests => 5;
use FindBin qw($Bin);
use_ok('Perlanet');
chdir $Bin;
ok(my $p = Perlanet->new, 'Object created');
isa_ok($p, 'Perlanet');

if (exists $p->cfg->{feed}{file} and -e $p->cfg->{feed}{file}) {
  unlink $p->cfg->{feed}{file};
}

if (exists $p->cfg->{page}{file} and -e $p->cfg->{page}{file}) {
  unlink $p->cfg->{page}{file};
}

$p->run;

ok(-e $p->cfg->{feed}{file}, 'Feed created');
ok(-e $p->cfg->{page}{file}, 'Page created');

if (exists $p->cfg->{feed}{file} and -e $p->cfg->{feed}{file}) {
  unlink $p->cfg->{feed}{file};
}

if (exists $p->cfg->{page}{file} and -e $p->cfg->{page}{file}) {
  unlink $p->cfg->{page}{file};
}
