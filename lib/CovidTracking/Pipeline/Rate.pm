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
    );

    my %last;
    for (my $i = $#{ $data }; $i >= 0; $i--) {
        my $datum = $data->[$i];
        my $state = $datum->{state} or next;
        my $last  = $last{$state};

        for my $field (sort keys %fields) {
            my $current = $datum->{$field};
            my $prev    = $last->{$field};
            next if grep { ! defined $_ } $current, $prev;

            my $currentTotal = $datum->{$fields{$field}};
            my $prevTotal    = $last->{$fields{$field}};
            next if grep { ! defined $_ } $currentTotal, $prevTotal;

            my $delta = $current - $prev;
            my $total = $currentTotal - $prevTotal;
            next if $total <= 0;

            $datum->{rate}{$field} = 100 * $delta / $total;
        }

        $last{$state} = $datum;
    }

    return $data;
}

1;
