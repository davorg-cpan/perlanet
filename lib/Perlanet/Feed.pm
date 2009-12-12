package Perlanet::Feed;
use Moose;

has 'title' => (
    isa => 'Str',
    is => 'rw',
);

has 'url' => (
    isa => 'Str',
    is => 'rw',
);

has 'website' => (
    isa => 'Str',
    is => 'rw',
);

has 'format' => (
    is => 'rw',
);

has '_xml_feed' => (
    isa => 'XML::Feed',
    is => 'rw',
    handles => [qw( entries )]
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
