use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	license            => 'perl',
	dist_author        => 'Dave Cross <dave@mag-sol.com>',
        module_name        => 'Perlanet',
	requires           => {
                "perl"                 => '5.6.0',
                "Encode"               => 0,
                "List::Util"           => 0,
                "LWP::UserAgent"       => 0,
                "XML::Feed"            => '0.22',
                "Template"             => 0,
                "DateTime"             => 0,
                "DateTime::Duration"   => 0,
                "YAML"                 => 0,
                "XML::OPML::SimpleGen" => 0,
                "HTML::Tidy"           => 0,
                "HTML::Scrubber"       => 0,
	},
        build_requires     => {
        	'Test::More'          => 0,
        },
	build_recommends   => {
		'Test::Pod'           => 0,
		'Test::Pod::Coverage' => 0,
	},
        create_makefile_pl => 'traditional',
        script_files       => [ 'bin/perlanet' ],
        meta_merge => {
            resources =>
            {
                repository => "git://github.com/davorg/perlanet.git",
                homepage => "http://code.mag-sol.com/Perlanet/",
                MailingList => "http://lists.mag-sol.com/mailman/listinfo/perlanet",
            },
            keywords =>
            [
            qw(
            aggregate
            aggregator
            atom
            feed
            planet
            rss
            xml
            ),
            ],
        },
);

$build->create_build_script;
