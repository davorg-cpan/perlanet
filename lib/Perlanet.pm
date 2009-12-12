package Perlanet;
use Moose;

use Carp;
use Encode;
use List::Util 'min';
use POSIX qw(setlocale LC_ALL);
use URI::Fetch;
use XML::Feed;
use Template;
use DateTime;
use DateTime::Duration;
use YAML 'LoadFile';
use HTML::Tidy;
use HTML::Scrubber;
use TryCatch;
use Perlanet::Feed;
use Perlanet::Entry;

use vars qw{$VERSION};

BEGIN {
    $VERSION = '0.37';
}

$XML::Atom::ForceUnicode = 1;

has 'cfg'  => (
    is => 'rw',
    isa => 'HashRef'
);

has 'ua' => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build => 1
);

has 'opml' => (
    is => 'rw',
    isa => 'XML::OPML::SimpleGen'
);

has 'cache'=> (
    is => 'rw'
);

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => $self->cfg->{agent} ||= "Perlanet/$VERSION"
    );
    $ua->show_progress(1) if -t STDOUT;
    $ua->env_proxy;

    return $ua;
}

has 'cutoff' => (
    isa => 'DateTime',
    is => 'ro',
    default => sub {
        DateTime->now + DateTime::Duration->new(weeks => 1);
    }
);

has 'feeds' => (
    isa => 'ArrayRef',
    is => 'ro',
    lazy_build => 1,
);

sub _build_feeds {
    my $self = shift;
    return [ map {
        Perlanet::Feed->new($_)
      } @{ $self->cfg->{feeds} } ];
}

has 'tidy' => (
    is => 'rw',
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
    is => 'rw',
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

=head1 NAME

Perlanet - A program for creating web pages that aggregate web feeds (both
RSS and Atom).

=head1 SYNOPSIS

  my $perlanet = Perlanet->new;
  $perlanet->run;

=head1 DESCRIPTION

Perlanet is a program for creating web pages that aggregate web feeds (both
RSS and Atom). Web pages like this are often called "Planets" after the Python
software which originally popularised them. Perlanet is a planet builder
written in Perl - hence "Perlanet".

The emphasis on Perlanet is firmly on simplicity. It reads web feeds, merges
them and publishes the merged feed as a web page and as a new feed. That's all
it is intended to do. If you want to do more with your feeds (create feeds
from inputs that don't publish feeds, filter or transform them in complex ways
or publish them in interesting ways) then Perlanet isn't the right software
for you. In that case I recommend that you take a look at Plagger - which is
another feed aggregator, but one that is far more complex and, therefore, far
more flexible.

For most uses, you probably don't want to use the Perlanet module. The
L<perlanet> command line program is far more likely to be useful.

=head1 METHODS

=head2 new

The constructor method. One optional argument which is the configuration file.
If not given, this defaults to C<./perlanetrc>.

=cut

sub BUILDARGS {
    my $class = shift;

    @_ or @_ = ('./perlanetrc');

    if ( @_ == 1 && ! ref $_[0] ) {
        open my $cfg_file, '<:utf8', $_[0]
            or croak "Cannot open file $_[0]: $!";
        return { cfg => LoadFile($cfg_file) };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub BUILD {
    my $self = shift;

    if ($self->cfg->{cache_dir}) {
        eval { require CHI; };
        
        if ($@) {
            warn "You need to install CHI to enable caching.\n";
            warn "Caching disabled for this run.\n";
            delete $self->cfg->{cache_dir};
        }
    }
    
    $self->cfg->{cache_dir}
        and $self->cache(CHI->new(
            driver     => 'File',
            root_dir   => $self->cfg->{cache_dir},
            expires_in => 60 * 60 * 24 * 30,
        ));
    
    my $opml;
    if ($self->cfg->{opml}) {
        eval { require XML::OPML::SimpleGen; };
        
        if ($@) {
            warn 'You need to install XML::OPML::SimpleGen to enable OPML ' .
                "Support.\n";
            warn "OPML support disabled for this run.\n";
            delete $self->cfg->{opml};
        } else {
            my $loc = setlocale(LC_ALL, 'C');
            $opml = XML::OPML::SimpleGen->new;
            setlocale(LC_ALL, $loc);
            $opml->head(
                title => $self->cfg->{title},
            );
            
            $self->opml($opml);
        }
    }
}

=head2 fetch_feed

Fetch a feed and return into as a L<XML::Feed>. If the feed cannot be fetched,
this will return C<undef>.

=cut

sub fetch_feeds
{
    my ($self, @feeds) = @_;

    my @valid_feeds;
    for my $feed (@feeds) {
        my $response = URI::Fetch->fetch($feed->url,
            UserAgent     => $self->ua,
            Cache         => $self->cache || undef,
            ForceResponse => 1,
        );

        next if !$response->is_success || $response->is_error;

        try {
            my $data = $response->content;
            my $xml_feed = XML::Feed->parse(\$data)
                or next;
            
            if ($xml_feed->format ne $self->cfg->{feed}{format}) {
                $xml_feed = $xml_feed->convert($feed->format);
            }

            $feed->_xml_feed($xml_feed);
            $feed->title($xml_feed->title) unless $feed->title;

            push @valid_feeds, $feed;
        }
        catch {
            warn "Errors parsing " . $feed->url;
        }
    }

    return @valid_feeds;
}

=head2 select_entries

Select all entries from a L<XML::Feed>, and sort them.

=cut

sub select_entries
{
    my ($self, @feeds) = @_;

    my @feed_entries;
    for my $feed (@feeds) {
        my @entries = $feed->entries;
        if ($self->cfg->{entries_per_feed} and
                @feed_entries > $self->cfg->{entries_per_feed}) {
            $#feed_entries = $self->cfg->{entries_per_feed} - 1;
        }

        push @feed_entries,
            map {
                $_->title($feed->title . ': ' . $_->title);
                Perlanet::Entry->new(
                    _entry => $_,
                    feed => $feed
                );
            } @entries;
    }

    return @feed_entries;
}

sub sort_entries
{
    my ($self, @entries) = @_;
    my $day_zero = DateTime->from_epoch(epoch => 0);
    return sort {
        ($b->modified || $b->issued || $day_zero)
            <=>
        ($a->modified || $a->issued || $day_zero)
    } @entries;
}

sub clean
{
    my ($self, $content) = @_;

    my $scrubbed = $self->scrubber->scrub($content);
    my $clean = $self->tidy->clean(utf8::is_utf8($scrubbed)
          ? $scrubbed
          : decode('utf8', $scrubbed));

    # hack to remove a particularly nasty piece of blogspot HTML
    $clean =~ s|<div align="justify"></div>||g;

    return $clean;
}

sub build_feed
{
    my ($self, @entries) = @_;
    
    my $f = XML::Feed->new($self->cfg->{feed}{format});
    $f->title($self->cfg->{title});
    $f->link($self->cfg->{url});
    $f->description($self->cfg->{description});
    $f->author($self->cfg->{author}{name});
    if ($self->cfg->{feed}{format} eq 'Atom') {
        my $p = $f->{atom}->author;
        $p->email($self->cfg->{author}{email});
    }
    $f->modified(DateTime->now);
    my $self_url = $self->cfg->{self_link} || $self->cfg->{feed}{url} ||
        $self->cfg->{url} . $self->cfg->{feed}{file};
    $f->self_link($self_url);
    $f->id($self_url);

    $f->add_entry($_->_entry) for @entries;
    return $f;
}

sub render
{
    my ($self, $feed) = @_;
    my $tt = Template->new;

    for my $entry ($feed->entries) {
        $entry->content->body($self->clean($entry->content->body)); 
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
}

sub save
{
    my ($self, $feed) = @_;
    open my $feedfile, '>', $self->cfg->{feed}{file}
        or croak 'Cannot open ' . $self->cfg->{feed}{file} . " for writing: $!";
    print $feedfile $feed->as_xml;
    close $feedfile;
}

sub update_opml {
    my $self = shift;

    return unless $self->opml;

    foreach my $f (@{$self->cfg->{feeds}}) {
        if ($self->opml) {
            $self->opml->insert_outline(
                title   => $f->{title},
                text    => $f->{title},
                xmlUrl  => $f->{url},
                htmlUrl => $f->{web},
            );
        }
    }
  
    $self->opml->save($self->cfg->{opml});
}

=head2 run

The main method which runs the perlanet process.

=cut

sub run {
    my $self = shift;

    $self->update_opml;
      
    my @entries = $self->select_entries(
        $self->fetch_feeds(@{ $self->feeds })
    );

    my $day_zero = DateTime->from_epoch(epoch => 0);
    my @feed_entries = grep {
        ($_->issued || $_->modified || $day_zero) < $self->cutoff
    } $self->sort_entries(@entries);

    # Only need so many entries
    if (@entries > $self->cfg->{entries}) {
        $#entries = $self->cfg->{entries} - 1;
    }

    # Build feed
    my $feed = $self->build_feed(@entries);
    $self->save($feed);
    $self->render($feed);
}

=head1 TO DO

See http://wiki.github.com/davorg/perlanet

=head1 SUPPORT

There is a mailing list which acts as both a place for developers to talk
about maintaining and improving Perlanet and also for users to get support.
You can sign up to this list at
L<http://lists.mag-sol.com/mailman/listinfo/perlanet>

To report bugs in Perlanet, please use the CPAN request tracker. You can
either use the web page at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Perlanet> or send an email
to bug-Perlanet@rt.cpan.org.

=head1 SEE ALSO

=over 4

=item *

L<perlanet>

=item *

L<Plagger>

=back

=head1 AUTHOR

Dave Cross, <dave@mag-sol.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Magnum Solutions Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
