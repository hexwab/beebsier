#!/usr/bin/perl -w

# clear arbitrary non-contiguous regions of memory

my $off=hex shift;
my $maxcycles=shift;
{local $/;$mem=<>;}
$size=length $mem;

my @lengths=(128,64,48,32,28,24,20,16,14,12,10,8,7,6,5,4,3,2);
#my @lengths = reverse(3..128);
my $loopmin=30; # loops must iterate at least this many times
my $loopmax=41; # loops must iterate at most this many times
my %out;
for my $s (@lengths,1) {
    my @s;
    my $tmp=$mem;
    my $it=0;
    for $o (0..$size-$s) {
	if (substr($tmp,$o,$s)=~/[^\x00]{$s}/ && ($s==1 || $it<$loopmax)) {
	    push @s, $o;
	    substr($tmp,$o,$s,"\x00"x$s);
	    $it++;
	}
    }
    next if $it<$loopmin;
    $mem=$tmp;
    $out{$s}=\@s;
}

die unless $mem eq "\x00"x$size;

my (%bytes, %cycles, %locs);

my $embiggenments=0;
my $savings=0;
my $cycles = scalar(@{$out{1}})*4;
for $s (@lengths) {
    next if not defined $out{$s};
    $cycles += $s*((scalar(@{$out{$s}})*5)+2+3)+2-1;
}

# make it bigger until we hit the cycle budget
while ($cycles>$maxcycles) {
    my $s=(grep { $out{$_} && @{$out{$_}} } (reverse @lengths))[0] or die;
    my $m=pop @{$out{$s}} or die;
    push @{$out{1}}, ($m..$m+$s-1);
    $embiggenments++;
    delete $out{$s} and $cycles-=$s*5+1,$savings+=$s*5+1 if !@{$out{$s}};
    $cycles-=$s;
    $savings+=$s;
}

printf STDERR "embiggened $embiggenments times, saved $savings cycles\n"
    if $embiggenments;

for $s (@lengths) {
    next if !defined $out{$s} or !@{$out{$s}};
    my ($t,$cc) = ($s==256) ? (0,'ne') : ($s-1,'pl');

    my @c=@{$out{$s}};
    #print STDERR "c=".scalar(@c)."\n";
    while (@c) {
	warn if @c>41;
	@d = splice @c, 0, 41; # (41+1)*3=126<128
	last unless @d;
	print <<EOF;
    ldx #$t
{ .loop
EOF

    #print STDERR "d=".scalar(@d)."\n";
	for my $a (@d) {
	    printf "sta \$%04x,X\n", $a+$off;
	}
	print <<EOF;
    dex
    b$cc loop
}
EOF

	$bytes{$s} += scalar(@d)*3+6;
	$cycles{$s} += $s*((scalar(@d)*5)+2+3)+2-1;
    }
}

for my $a (@{$out{1}}) {
    printf "sta \$%04x\n", $a+$off;
}
$bytes{1} = scalar(@{$out{1}})*3;
$cycles{1} = scalar(@{$out{1}})*4;

my ($locs,$bytes,$newcycles);
print STDERR "n\tlocations\tbytes\tcycles\n";
for (sort {$a<=>$b} keys %out) {
    my $l=scalar(@{$out{$_}});
    next unless $l;
    print STDERR "$_\t$l\t\t$bytes{$_}\t$cycles{$_}\n";
    $locs+=$l;
    $bytes+=$bytes{$_};
    $newcycles+=$cycles{$_};
}

printf STDERR "total\t$locs\t\t$bytes\t$cycles\n";
die "$cycles!=$newcycles" if $cycles!=$newcycles;
