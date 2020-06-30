package CovidTracking::Pipeline::Rate;
use List::Util qw( sum );
use Moo;

sub run {
    my ($self, $data) = @_;

    my %fields = (
        negative           => 'totalTestResults',
        positive           => 'totalTestResults',
        negativeTestsViral => 'totalTestsViral',
        positiveTestsViral => 'totalTestsViral',
        death              => ['death', 'recovered'],
        recovered          => ['death', 'recovered'],
    );

    for my $datum (@$data) {
        my $state = $datum->{state} or next;

        FIELD: for my $field (sort keys %fields) {
            my $value = $datum->{$field};
            next if ! defined $value;

            my $total;
            if ( ref($fields{$field}) ) {
                my @args = @{ $datum }{ @{ $fields{$field} } };
                next FIELD if grep { ! defined $_ } @args;
                $total = sum(@args);
            } else {
                $total = $datum->{$fields{$field}};
            }
            next if ! $total;

            $datum->{rate}{$field} = 100 * $value / $total;
        }
    }

    return $data;
}

1;
