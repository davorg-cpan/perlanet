use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  license            => 'perl',
  dist_author        => 'Dave Cross <dave@perlhacks.com>',
  module_name        => 'Perlanet',
  requires           => {
    'perl'                 => '5.34.0',
    'Encode'               => 0,
    'List::Util'           => 0,
    'URI::Fetch'           => 0,
    'XML::Feed'            => '0.22',
    'Template'             => 0,
    'DateTime'             => 0,
    'DateTime::Duration'   => 0,
    'YAML'                 => 0,
    'Alien::TidyHTML5'     => 0,
    'HTML::T5'             => 0,
    'HTML::Scrubber'       => 0,
    'Moose'                => 0,
    'MooseX::Traits'       => 0,
    'namespace::autoclean' => 0,
    'MooseX::ConfigFromFile' => 0,
    'DateTime::Format::Strptime' => 0,
    # I mean, it's possible to use the module without this
    # - but it's pretty unlikely
    'LWP::Protocol::https' => 0,
  },
  recommends         => {
    'CHI'                    => 0,
    'Compress::Zlib'         => 0,
    'XML::OPML::SimpleGen'   => 0,
    'MooseX::ConfigFromFile' => 0,
  },
  build_requires     => {
    'Test::More'             => 0,
    'File::Path'             => 0,
    'MooseX::ConfigFromFile' => 0,
    'Alien::TidyHTML5'       => 0,
    'XML::OPML::SimpleGen'   => 0,
    'Test::Warnings'         => 0,
  },
  build_recommends   => {
    'Test::Pod'              => 0,
    'Test::Pod::Coverage'    => 0,
  },
  create_makefile_pl => 'traditional',
  script_files       => [ 'bin/perlanet' ],
  meta_merge => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
       type => 'git',
       url  => 'git://github.com/davorg-cpan/perlanet.git',
       web  => 'https://github.com/davorg-cpan/perlanet',
     },
      bugtracker => {
       web  => 'https://github.com/davorg-cpan/perlanet/issues',
     },
     homepage => "http://perlanet.mag-sol.com/",
   },
   keywords => [ qw(
     aggregate
     aggregator
     atom
     feed
     planet
     rss
     xml
   ), ],
 },
);

$build->create_build_script;
