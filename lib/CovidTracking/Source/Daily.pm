package CovidTracking::Source::Daily;
use File::Basename qw( dirname );
use File::Spec;
use HTTP::Tiny;
use IO::File;
use JSON::PP qw( decode_json encode_json );
use Moo;

has file => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_file',
);
sub _build_file {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data daily.json )
    );
}

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

sub states {
    my $url = 'https://covidtracking.com/api/v1/states/daily.json';
    my $res = HTTP::Tiny->new->get($url);
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n";
    }

    my $decoded = eval { decode_json($res->{content}) };
    if ( ! $decoded ) {
        ...
    }

    return $decoded;
}

sub total {
    my $url = 'https://covidtracking.com/api/v1/us/daily.json';
    my $res = HTTP::Tiny->new->get($url);
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n";
    }

    my $decoded = eval { decode_json($res->{content}) };
    if ( ! $decoded ) {
        ...
    }

    $_->{state} = 'total' for @$decoded;
    return $decoded;
}

sub load {
    my ($self) = @_;
    my $path   = $self->file;
    if ( -e $path && ! $self->update ) {
        my $fh     = IO::File->new($path, 'r')
            or die "cannot open $path for reading: $!";

        local $@;
        my $contents = join '', $fh->getlines();
        my $decoded  = eval { decode_json($contents) };
        if ( ! $decoded ) {
            ...
        }

        return $decoded;
    } else {
        my $states = $self->states;
        my $total  = $self->total;
        return [ @$states, @$total ];
    }
}

sub run {
    my ($self) = @_;
    my $file   = $self->file;
    my $data   = $self->load();

    if ( $file && $self->update ) {
        my $fh = IO::File->new($file, 'w')
            or die "cannot open $file for writing: $!";
        $fh->print(encode_json($data));
    }

    return $data;
}

1;
