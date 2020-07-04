package CovidReporting::Pipeline::PerMillion;
use Carp;
use File::Basename qw( dirname );
use File::Spec;
use IO::File;
use JSON::PP qw( decode_json );
use Locale::Country qw( code2country country2code LOCALE_CODE_ALPHA_3 LOCALE_CODE_NUMERIC );
use Moo;
with qw( CovidReporting::Role::Loader );

has countries => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_countries',
);
sub _build_countries {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data countries.json )
    );
}

has states => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_states',
);
sub _build_states {
    return File::Spec->catfile(
        dirname(__FILE__),
        qw( .. .. .. data states.json )
    );
}

has populations => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_populations',
);
sub _build_populations {
    my ($self) = @_;
    my %populations;

    my $countries = $self->load_file($self->countries);
    for my $id ( grep { /^\d+$/ } sort keys %$countries ) {
        my $country = code2country($id, LOCALE_CODE_NUMERIC);
        my $alpha   = country2code($country, LOCALE_CODE_ALPHA_3);
        $countries->{ $alpha } = 1000 * delete($countries->{ $id });
    }
    $populations{country} = $countries;

    $populations{state} = $self->load_file($self->states);;

    return \%populations;
}

sub load {
    my ($self, $file) = @_;
    my ($ext) = $file =~ / \. (.*)? $/x;
    if (my $code = $self->can("_load_$ext")) {
        return $self->$code($file);
    } else {
        croak "ERROR could not load $file: unrecognized extension $ext";
    }
}

sub scale {
    my ($self, $datum, $population) = @_;
    my %scaled;

    for my $field (sort keys %$datum) {
        my $value = $datum->{$field};
        next if ! defined($value);
        if ( ref($value) ) {
            $scaled{$field} = $self->scale($value, $population);
        } else {
            $scaled{$field} = 10**6 * $value / $population;
        }
    }

    return \%scaled;
}

sub run {
    my ($self, $data) = @_;
    my $populations   = $self->populations;

    for my $datum (@$data) {
        my $country = $datum->{metadata}{country} or next;
        if ( my $state = $datum->{metadata}{state} ) {
            my $population = $populations->{state}{$state} or next;
            $datum->{values}{perMillion} = $self->scale($datum->{values}, $population);
        } else {
            my $population = $populations->{country}{$country} or next;
            $datum->{values}{perMillion} = $self->scale($datum->{values}, $population);
        }
    }

    return $data;
}

1;
