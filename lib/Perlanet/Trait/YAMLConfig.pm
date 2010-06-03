package Perlanet::Trait::YAMLConfig;
use Moose::Role;
use namespace::autoclean;

with 'MooseX::ConfigFromFile';

use Carp qw( carp croak );
use YAML qw( LoadFile );

use constant THIRTY_DAYS => 30 * 24 * 60 * 60;

sub get_config_from_file {
    my ($self, $file) = @_;

    open my $cfg_file, '<:utf8', $file
      or croak "Cannot open file $file: $!";

    my $cfg = LoadFile($cfg_file);

    $cfg->{feeds} = [ map {
        Perlanet::Feed->new($_)
      } @{ $cfg->{feeds} } ];

    $cfg->{max_entries} = $cfg->{entries}
        if $cfg->{entries};

    if ($cfg->{cache_dir}) {
        eval { require CHI; };

        if ($@) {
            carp "You need to install CHI to enable caching.\n";
            carp "Caching disabled for this run.\n";
            delete $cfg->{cache_dir};
        }
    }

    delete $cfg->{cache_dir}
        and $cfg->{cache} = CHI->new(
            driver     => 'File',
            root_dir   => $cfg->{cache_dir},
            expires_in => THIRTY_DAYS,
        );

    return $cfg;
}

1;
