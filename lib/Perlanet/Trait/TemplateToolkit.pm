package Perlanet::Trait::TemplateToolkit;
use Moose::Role;
use namespace::autoclean;

use Template;

has 'template_input' => (
    isa       => 'Str',
    is        => 'rw',
    predicate => 'has_template',
);

has 'template_output' => (
    isa       => 'Str',
    is        => 'rw',
    predicate => 'has_output',
);

after 'render' => sub {
    my ($self, $feed) = @_;
    my $tt = Template->new;
    $tt->process(
        $self->template_input,
        {
            feed => $feed,
        },
        $self->template_output,
        {
            binmode => ':utf8'
        }
    ) or croak $tt->error;
};

1;
