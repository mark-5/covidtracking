package CovidReporting::Source::OWID;
use File::Basename qw( dirname );
use File::Spec;
use HTTP::Tiny;
use IO::File;
use Text::ParseWords qw( parse_line );
use Moo;
with qw( CovidReporting::Role::Source );

has '+file' => (
    lazy    => 1,
    builder => '_build_file',
);
sub _build_file {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data owid.csv )
    );
}

sub format {
    my ($self, $datum) = @_;
    my %mapping        = (
        total_cases  => 'cases',
        total_deaths => 'deaths',
        total_tests  => 'tests',
    );

    my $values = {};
    for my $label (sort keys %mapping) {
        my $value = $datum->{$label};
        next if ! defined $value or ! length($value);
        $values->{  $mapping{$label} } = $value;
    }

    return {
        values   => $values,
        metadata => {
            country => $datum->{iso_code},
            date    => $datum->{date},
            source  => 'owid',
        },
    };
}

sub countries {
    my ($self) = @_;
    my $url    = 'https://github.com/owid/covid-19-data/raw/master/public/data/owid-covid-data.csv';
    my $res    = HTTP::Tiny->new->get($url);
    if ( ! $res->{success} ) {
        die "error getting $url: $res->{status} $res->{reason}\n\n$res->{content}";
    }

    return $self->load_csv($res->{content});
}

sub load {
    my ($self) = @_;
    return $self->countries;
}

sub run {
    my ($self) = @_;
    my $data   = $self->load();
    return [ map { $self->format($_) } @$data ];
}

1;
