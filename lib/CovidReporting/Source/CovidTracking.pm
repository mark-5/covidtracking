package CovidReporting::Source::CovidTracking;
use File::Basename qw( dirname );
use File::Spec;
use HTTP::Tiny;
use IO::File;
use JSON::PP qw( decode_json encode_json );
use Moo;
with qw( CovidReporting::Role::Source );

has '+file' => (
    lazy    => 1,
    builder => '_build_file',
);
sub _build_file {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data covidtracking.csv )
    );
}

sub states {
    my ($self) = @_;
    my $url    = 'https://covidtracking.com/api/v1/states/daily.csv';
    my $res    = HTTP::Tiny->new->get($url);
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n\n$res->{content}";
    }

    return $self->load_csv($res->{content});
}

sub total {
    my ($self) = @_;
    my $url    = 'https://covidtracking.com/api/v1/us/daily.csv';
    my $res    = HTTP::Tiny->new->get($url);
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n\n$res->{content}";
    }

    return $self->load_csv($res->{content});
}

sub format {
    my ($self, $datum) = @_;
    my %mapping        = (
        positive               => 'cases',
        death                  => 'deaths',
        recovered              => 'recovered',
        totalTestResults       => 'tests',
        hospitalizedCurrently  => [ 'hospitalized', 'current' ],
        hospitalizedCumulative => [ 'hospitalized', 'total'   ],
        inIcuCurrently         => [ 'inIcu',        'current' ],
        inIcuCumulative        => [ 'inIcu',        'total'   ],
        onVentilatorCurrently  => [ 'onVentilator', 'current' ],
        onVentilatorCumulative => [ 'onVentilator', 'total'   ],
    );

    my $values = {};
    for my $label (sort keys %mapping) {
        my $value = $datum->{$label};
        next if ! defined $value or ! length($value);

        my $field = $mapping{$label};
        if ( ref($field) ) {
            my $slot = $values;
            for (my $i = 0; $i < $#{ $field }; $i++) {
                $slot = $slot->{ $field->[$i] } ||= {};
            }
            $slot->{ $field->[-1] } = $value;
        } else {
            $values->{$field} = $value;
        }
    }

    my ($y,$m,$d) = $datum->{date} =~ /^(\d{4})(\d{2})(\d{2})$/;
    return {
        values   => $values,
        metadata => {
            country   => 'USA',
            date      => "$y-$m-$d",
            state     => $datum->{state},
            source    => 'covidtracking',
			total	  => ! $datum->{state},
        },
    };
}

sub load {
    my ($self) = @_;
    my $states = $self->states;
    my $total  = $self->total;
    return [ @$states, @$total ];
}

sub run {
    my ($self) = @_;
    my $data   = $self->load();
    return [ map { $self->format($_) } @$data ];
}

1;
