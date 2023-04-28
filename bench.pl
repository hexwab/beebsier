#!/usr/bin/perl -w

use JSON::PP;
my $sym;
while (<>) {
    /\[\{/ or next; s/L([,}])/$1/g; s/\'/"/g;
    $sym = ${decode_json$_}[0];
}
die unless $sym->{zpstart};

my @locs = map{ sprintf"%04X",$sym->{$_}-$sym->{zpstart}} qw[trace4 trace1 trace2 trace3];
my $count=128;
my $commands = join("",map{"b $_;c;r;db 0;"} @locs)x$count."q";


open F, "beebjit -debug -autoboot -0 sier.ssd -opt sound:off -headless -commands '$commands'|" or die $!;

my %cycles;
my %deltas;
my %splitdeltas;
my $last;
while (<F>) {
    next unless /PC=(....) cycles=(\d+)/;
    push @{$deltas{$1}}, $2-${$cycles{$1}}[$#{$cycles{$1}}] if $cycles{$1};
    push @{$cycles{$1}},$2;
    push @{$splitdeltas{$1}}, $2-$last if $last;
    $last=$2;
}
use Data::Dumper;
#print Dumper \%cycles;
#print Dumper \%splitdeltas;
#print Dumper \%deltas;

my @places=qw[sync misc early late];
print "\t  min\t  max\t  mean\tstddev\n";
for (0..3) {
    printf "%s\t%6d\t%6d\t%6d\t%6.2f\n", $places[$_], stats(@{$splitdeltas{$locs[$_]}});
}
printf "total\t%6d\t%6d\t%6d\t%6.2f\n", stats(@{$deltas{$locs[0]}});
printf "fps\t%2.3f\t%2.3f\t%2.3f\t%4.4f\n", stats(map{2e6/$_}@{$deltas{$locs[0]}});
#printf "fps: min %.3f max %.3f mean %.3f±%.5f\n", stats(map{2e6/$_}@{$deltas{$locs[3]}});

sub stats {
    my ($min,$max,$sum,$sqsum);
    $min=$max=$_[0];
    for (@_) {
	$min=$_ if $min>$_;
	$max=$_ if $max<$_;
	$sum+=$_;
	$sqsum+=$_*$_;
    }
    my $count=scalar@_;
    my $mean=$sum/$count;
    my $variance=$sqsum/$count - $mean*$mean;
    return ($min, $max, $mean, sqrt($variance));
}
