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

our %LAST;
sub format {
    my ($self, $datum) = @_;
    my $country        = $datum->{iso_code} or return;
    $country           = undef if $country eq 'OWID_WRL';
    my %mapping        = (
        total_cases  => 'cases',
        total_deaths => 'deaths',
        total_tests  => 'tests',
        total_cases_per_million  => [ 'perMillion', 'cases'  ],
        total_deaths_per_million => [ 'perMillion', 'deaths' ],
        total_tests_per_thousand => [ 'perMillion', 'tests'  ],
    );
    my %daily = (
        total_tests              => 'new_tests',
        total_tests_per_thousand => 'new_tests_per_thousand',
    );

    my $values = {};
    for my $label (sort keys %mapping) {
        my $value = $datum->{$label};
        my $daily = $daily{$label};
        if ( ( ! defined $value or ! length($value) ) and $daily ) {
            my $new = delete($datum->{$daily});
            next if ! defined $new or ! length($new);

            my $total = $LAST{ $country }{ $daily } || 0;
            $value    = $LAST{ $country }{ $daily } = $total + $new;
        }
        next if ! defined $value or ! length($value);

        my $field = $mapping{$label};
        if ( ref($field) ) {
            my $slot = $values;
            for (my $i = 0; $i < $#{ $field }; $i++) {
                $slot = $slot->{ $field->[$i] } ||= {};
            }
            $slot->{ $field->[-1] }  = $value;
            $slot->{ $field->[-1] } *= 1000 if $label =~ /_per_thousand$/;
        } else {
            $values->{$field} = $value;
        }
    }

    return {
        values   => $values,
        metadata => {
            country => $country,
            date    => $datum->{date},
            source  => 'owid',
            total   => ! $country,
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
    my ($self)  = @_;
    my $records = $self->load();
    local(%LAST);

    my @data;
    while ( my $record = pop(@$records) ) {
        push @data, $self->format($record);
    }
    return \@data;
}

1;
