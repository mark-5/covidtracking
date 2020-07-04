package CovidReporting::Role::Loader;
use Carp;
use IO::File;
use JSON::PP qw( decode_json );
use Text::ParseWords qw( parse_line );
use Moo::Role;

sub load_csv {
    my ($self, $file) = @_;

    my @lines;
    if ( ref($file) ) {
        @lines = $file->getlines();
    } else {
        @lines = split(/\n/, $file);
    }
    s/\s+$// for @lines;

    my @data;
    my @headers = parse_line(',', 0, $lines[0]);
    for my $line ( @lines[ 1 .. $#lines ] ) {
        my $datum  = {};
        my @values = parse_line(',', 0, $line);
        for (my $i = 0; $i < @values; $i++) {
            my $value = $values[$i];
            next if ! defined($value) or ! length($value);
            $datum->{ $headers[$i] } = $value
        }
        push @data, $datum;
    }

    return \@data;
}

sub load_json {
    my ($self, $file) = @_;
    my $contents = $file;
    $contents    = join('', $file->getlines()) if ref($file);

    my $decoded = eval { decode_json($contents) };
    if ( ! $decoded ) {
        die;
    }

    return $decoded;
}

sub load_file {
    my ($self, $file) = @_;
    my ($ext) = $file =~ / \. ([^.]+) $ /x;
    my $code  = $self->can("load_$ext")
        or croak "cannot load $file: $ext is an unsupported extension";

    my $fh = IO::File->new($file, 'r')
        or croak "cannot open $file for reading: $!";
    return $self->$code($fh);
}

sub write_file {
    my ($self, $file, $data) = @_;
    my ($ext) = $file =~ / \. ([^.]+) $ /x;
    my $code  = $self->can("write_$ext")
        or croak "cannot write $file: $ext is an unsupported extension";

    return $self->$code($file, $data);
}

sub write_csv {
    my ($self, $file, $rows) = @_;
    my $fh = IO::File->new($file, 'w')
        or croak "cannot open $file for writing: $!";

    my $ref = ref($rows->[0]);
    if ( $ref eq 'ARRAY' ) {
        for my $row (@$rows) {
            $fh->print(join(',', map { $_ // '' } @$row), "\n");
        }
    } elsif ( $ref eq 'HASH' ) {
        my %fields  = map { %$_ } @$rows;
        my @headers = sort keys %fields;
        $fh->print(join(',', @headers), "\n");
        for my $row (@$rows) {
            $fh->print(join(',', map { $row->{$_} // '' } @headers), "\n");
        }
    } else {
        die "cannot write csv $file: unrecognized ref $ref";
    }
}

sub write_json {
    my ($self, $file, $data) = @_;
    my $fh = IO::File->new($file, 'w')
        or croak "cannot open $file for writing: $!";
    $fh->print(encode_json($data));
}

1;
