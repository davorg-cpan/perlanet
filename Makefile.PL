use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'perlanet',
    VERSION_FROM      => 'perlanet',
    EXE_FILES         => [ 'perlanet' ],
    PREREQ_PM         => {
        Encode => 0,
        Encode::Detect => 0,
        List::Util => 0,
        LWP::Simple => 0,
        XML::Feed => 0,
        Template => 0,
        DateTime => 0,
        DateTime::Duration => 0,
        YAML => 0,
        XML::OPML::SimpleGen => 0,
        HTML::Tidy => 0,
        HTML::Scrubber => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT  => 'Perlanet - A program for creating web pages that aggregate web feeds (both RSS and Atom).',
       AUTHOR         => 'Dave Cross, <dave@mag-sol.com>') : ()),
);
