#!/usr/bin/perl -wl
for my $p (0..3) {
    my $o=3-$p;
    my @out=();
    for my $i (0..255) {
	my $j=$i>>$o;
	my $a=(($j & 0x10)?2:0) + ($j &1);
	if ($a==3) {
	    #printf "i=%02x j=%02x a=%02x [skipping]\n", $i, $j, $a;
	    push @out,0;
	} else {
	    $a++;
	    my $k=$i & ~(0x11<<$o);
	    my $l=(($a & 1) + (($a & 2)<<3))<<$o;
	    #printf "i=%02x j=%02x a=%02x m=%02x k=%02x l=%02x\n", $i,$j,$a,(0x11<<$o),$k,$l;
	    die if $k & $l;
	    push @out,(($k|$l)-$i)&0xff;
	}
    }
    print ".inc$p equb ",join",",map{sprintf'$%02x',$_}@out;
}
