package CovidReporting::Role::Source;
use Carp;
use Moo::Role;
with qw( CovidReporting::Role::Loader );

has file => (
    is       => 'ro',
    required => 1,
);

has update => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_update',
);
sub _build_update {
    my ($self) = @_;
    my $file   = $self->file;
    return $file && ! -e $file;
}

around load => sub {
    my ($orig, $self) = @_;
    my $file = $self->file;
    return $self->load_file($file) if -e $file && ! $self->update;

    my $data = $self->$orig();
    $self->write_file($file, $data) if $file && $self->update;

    return $data;
};

sub run { shift->load() }

1;
