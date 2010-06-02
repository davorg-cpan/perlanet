package Perlanet::Simple;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Carp;
use HTML::Scrubber;
use HTML::Tidy;
use POSIX qw(setlocale LC_ALL);
use YAML 'LoadFile';
use Template;

extends 'Perlanet';
with 'Perlanet::Trait::Cache',
     'Perlanet::Trait::OPML';

use constant THIRTY_DAYS => 30 * 24 * 60 * 60;

has 'cfg'  => (
  is  => 'rw',
  isa => 'HashRef'
);

has 'tidy' => (
  is         => 'rw',
  lazy_build => 1
);

sub _build_tidy {
  my $self = shift;
  my %tidy = (
    doctype           => 'omit',
    output_xhtml      => 1,
    wrap              => 0,
    alt_text          => '',
    break_before_br   => 0,
    char_encoding     => 'raw',
    tidy_mark         => 0,
    show_body_only    => 1,
    preserve_entities => 1,
    show_warnings     => 0,
  );

  my $tidy = HTML::Tidy->new(\%tidy);
  $tidy->ignore( type => TIDY_WARNING );

  return $tidy;
}

has 'scrubber' => (
  is         => 'rw',
  lazy_build => 1
);

sub _build_scrubber {
  my $self = shift;

  my %scrub_rules = (
    img => {
      src   => qr{^http://},    # only URL with http://
      alt   => 1,               # alt attributes allowed
      align => 1,               # allow align on images
      style => 1,
      '*'   => 0,               # deny all others
    },
    style => 0,
    script => 0,
    span => {
      id => 0,                  # blogger(?) includes spans with id attribute
    },
    a => {
      href => 1,
      '*'  => 0,
    },
  );

  # Definitions for HTML::Scrub
  my %scrub_def = (
    '*'           => 1,
    'href'        => qr{^(?!(?:java)?script)}i,
    'src'         => qr{^(?!(?:java)?script)}i,
    'cite'        => '(?i-xsm:^(?!(?:java)?script))',
    'language'    => 0,
    'name'        => 1,
    'value'       => 1,
    'onblur'      => 0,
    'onchange'    => 0,
    'onclick'     => 0,
    'ondblclick'  => 0,
    'onerror'     => 0,
    'onfocus'     => 0,
    'onkeydown'   => 0,
    'onkeypress'  => 0,
    'onkeyup'     => 0,
    'onload'      => 0,
    'onmousedown' => 0,
    'onmousemove' => 0,
    'onmouseout'  => 0,
    'onmouseover' => 0,
    'onmouseup'   => 0,
    'onreset'     => 0,
    'onselect'    => 0,
    'onsubmit'    => 0,
    'onunload'    => 0,
    'src'         => 1,
    'type'        => 1,
    'style'       => 1,
    'class'       => 0,
    'id'          => 0,
  );

  my $scrub = HTML::Scrubber->new;
  $scrub->rules(%scrub_rules);
  $scrub->default(1, \%scrub_def);

  return $scrub;
}

sub BUILDARGS {
  my $class = shift;

  @_ or @_ = ('./perlanetrc');

  if ( @_ == 1 && ! ref $_[0] ) {
    open my $cfg_file, '<:utf8', $_[0]
      or croak "Cannot open file $_[0]: $!";

    my $cfg = LoadFile($cfg_file);
    my $args = {
        cfg   => $cfg,
        feeds => [ map {
            Perlanet::Feed->new($_)
          } @{ $cfg->{feeds} } ]
    };

    if ($cfg->{cache_dir}) {
        eval { require CHI; };

        if ($@) {
            carp "You need to install CHI to enable caching.\n";
            carp "Caching disabled for this run.\n";
            delete $cfg->{cache_dir};
        }
    }

    $cfg->{cache_dir}
        and $args->{cache} = CHI->new(
            driver     => 'File',
            root_dir   => $cfg->{cache_dir},
            expires_in => THIRTY_DAYS,
        );

    my $opml;
    if ($cfg->{opml}) {
        eval { require XML::OPML::SimpleGen; };

        if ($@) {
            carp 'You need to install XML::OPML::SimpleGen to enable OPML ' .
                "Support.\n";
            carp "OPML support disabled for this run.\n";
            delete $cfg->{opml};
        } else {
            my $loc = setlocale(LC_ALL, 'C');
            $opml = XML::OPML::SimpleGen->new;
            setlocale(LC_ALL, $loc);
            $opml->head(
                title => $cfg->{title},
            );

            $args->{opml} = $opml;
        }
    }

    return $args;
  } else {
    return $class->SUPER::BUILDARGS(@_);
  }
}

around '_build_ua' => sub {
  my $orig = shift;
  my $self = shift;
  my $ua = $self->$orig;
  $ua->agent($self->cfg->{agent}) if $self->cfg->{agent};
  return $ua;
};

override 'render' => sub {
    my ($self, $feed) = @_;

    my $tt = Template->new;

    for my $entry (@{ $feed->entries }) {
        $self->clean($entry->content->body);
    }

    $tt->process(
        $self->cfg->{page}{template},
        {
            feed => $feed,
            cfg => $self->cfg
        },
        $self->cfg->{page}{file},
        {
            binmode => ':utf8'
        }
    ) or croak $tt->error;

    open my $feedfile, '>', $self->cfg->{feed}{file}
        or croak 'Cannot open ' . $self->cfg->{feed}{file} . " for writing: $!";
    print $feedfile $feed->as_xml($self->cfg->{feed}{format});
    close $feedfile;

    return;
};

1;
