package Perlanet::Trait::FeedFile;
use Moose::Role;
use namespace::autoclean;

use Carp qw( croak );
use Template;

has 'feed_file' => (
    isa       => 'Str',
    is        => 'rw',
    predicate => 'has_feed_file',
);

has 'feed_format' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'RSS',
);

after 'render' => sub {
    my ($self, $feed) = @_;
    return unless $self->has_feed_file;

    open my $feedfile, '>', $self->feed_file
        or croak 'Cannot open ' . $self->feed_file . " for writing: $!";
    print $feedfile $feed->as_xml($self->feed_format);
    close $feedfile;
};

1;
