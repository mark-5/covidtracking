package CovidReporting::Pipeline::Daily;
use Moo;

sub run {
    my ($self, $data) = @_;

    my %total;
    for my $datum (reverse @$data) {
        my $country = $datum->{metadata}{country}     or next;
        my $daily   = delete($datum->{values}{daily}) or next;
        for my $field (keys %$daily) {
            my $new = $daily->{ $field };
            next if ! defined $new or ! length($new);

            if ( ref($new) ) {
                for my $key (keys %$new) {
                    $new = $daily->{ $field }{ $key };
                    next if ! defined $new or ! length($new);

                    my $total = $total{ $country }{ $field }{ $key } || 0;
                    $datum->{ $field }{ $key } = $total{ $country }{ $field }{ $key } = $total + $new;
                }
            } else {
                my $total = $total{ $country }{ $field } || 0;
                $datum->{ $field } = $total{ $country }{ $field } = $total + $new;
            }
        }
    }

    return $data;
}

1;
