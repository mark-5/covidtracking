package CovidTracking::Pipeline::PerMillion;
use File::Basename qw( dirname );
use File::Spec;
use IO::File;
use JSON::PP qw( decode_json );
use Moo;

has file => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_file',
);
sub _build_file {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data populations.json )
    );
}

has populations => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_populations',
);
sub _build_populations {
    my ($self) = @_;
    my $file   = $self->file;

    my $fh     = IO::File->new($file, 'r')
        or die "could not open $file for reading: $!";

    local $@;
    my $contents = join '', $fh->getlines();
    my $decoded  = eval { decode_json($contents) };
    if ( ! $decoded ) {
        ...
    }

    return $decoded;
}

sub run {
    my ($self, $data) = @_;
    my $populations   = $self->populations;

    for my $datum (@$data) {
        my $state      = $datum->{state};
        my $population = $populations->{$state} or next;

        for my $field (qw(
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
        )) {
            my $value = $datum->{$field};
            next if ! defined $value;
            $datum->{perMillion}{$field} = 10**6 * $value / $population;
        }
    }

    return $data;
}

1;
