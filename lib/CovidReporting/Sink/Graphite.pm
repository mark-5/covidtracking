package CovidReporting::Sink::Graphite;
use IO::Socket::INET;
use Time::Piece;
use Moo;

has graphite => (
    is      => 'ro',
    builder => '_build_graphite',
    lazy    => 1,
);
sub _build_graphite {
    my $s = IO::Socket::INET->new(
        PeerHost => 'localhost',
        PeerPort => 2003,
        Proto    => 'tcp',
    ) or die "cannot connect to graphite: $!";
    return $s;
}

has _parsed => (
    is      => 'ro',
    default => sub { +{} },
    lazy    => 1,
);
sub parse {
    my ($self, $date) = @_;
    return $self->_parsed->{$date} ||= do {
        my $t = Time::Piece->strptime("$date", "%Y-%m-%d");
        $t->epoch;
    };
}

sub metrics {
    my ($self, $datum, $base) = @_;

    my @metrics;
    for my $field (sort keys %$datum) {
        my $value = $datum->{$field};
        if ( ref($value) ) {
            push @metrics, $self->metrics($value, "$base.$field");
        } elsif ( defined($value) ) {
            push @metrics, [ "$base.$field", $value ];
        }
    }

    return @metrics;
}

sub load {
    my ($self, $datum) = @_;
    my $date           = $datum->{metadata}{date}    or return;
    my $country        = $datum->{metadata}{country} or return;
    my $epoch          = $self->parse($date)          or return;
    my $graphite       = $self->graphite;

    my $base = $datum->{metadata}{source};
    if ( my $state = $datum->{metadata}{state} ) {
        $base .= ".state.$state";
    } else {
        $base .= ".country.$country";
    }

    for my $metric ( $self->metrics($datum->{values}, $base) ) {
        $graphite->print("$metric->[0] $metric->[1] $epoch\n");
    }

    return;
}

sub run {
    my ($self, $data) = @_;

    for my $datum (@$data) {
        $self->load($datum);
    }
}

1;
