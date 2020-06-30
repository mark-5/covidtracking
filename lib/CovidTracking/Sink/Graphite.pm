package CovidTracking::Sink::Graphite;
use IO::Socket::INET;
use Time::Piece;
use Moo;

has fields => (
    is      => 'ro',
    builder => '_build_fields',
    lazy    => 1,
);
sub _build_fields {
    return [qw(
        death
        hospitalizedCumulative
        hospitalizedCurrently
        inIcuCumulative
        inIcuCurrently
        negative
        negativeTestsViral
        onVentilatorCumulative
        onVentilatorCurrently
        pending
        positive
        positiveCasesViral
        positiveTestsViral
        recovered
        totalTestResults
        totalTestsViral
    )];
}

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
        my $t = Time::Piece->strptime("$date", "%Y%m%d");
        $t->epoch;
    };
}

sub load {
    my ($self, $datum) = @_;
    my $fields         = $self->fields;
    my $date           = $datum->{date}  or return;
    my $state          = $datum->{state} or return;
    my $epoch          = $self->parse($date) or return;
    my $graphite       = $self->graphite;

    my $base = $state eq 'total' ? 'covid19.total' : "covid19.state.$state";
    for my $field (@$fields) {
        if (defined( my $value = $datum->{$field} )) {
            $graphite->print("$base.$field $value $epoch\n");
        }
        if (defined( my $value = $datum->{perMillion}{$field} )) {
            $graphite->print("$base.perMillion.$field $value $epoch\n");
        }
        if (defined( my $value = $datum->{rate}{$field} )) {
            $graphite->print("$base.rate.$field $value $epoch\n");
        }
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
