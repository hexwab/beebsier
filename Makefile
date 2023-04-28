EXO=exomizer
BEEBASM=beebasm
BBCIM=bbcim
PYTHON=python3
PERL=perl
BEEBJIT=beebjit

sier.ssd: coords.s inc.s sier.s mem Makefile
	${BEEBASM} -i sier.s -d -v >out.txt
	-rm -f sier.ssd
	if ${EXO} sfx 0x1100 -P+63 -n -D i_irq_during=0 -Di_irq_exit=0 -s 'sec .BYTE($$66) .BYTE($$ff) .BYTE($$d0) .BYTE(24) .TEXT("github.com/hexwab/beebsier") lda #126 jsr $$fff4' -t 0xbbcb sier@0x1100 -o '!BOOT'  ; then \
		${BBCIM} -a sier.ssd '!BOOT' ; \
		${BBCIM} -boot sier.ssd RUN  ; \
		${BEEBJIT} -debug -autoboot -0 sier.ssd -opt sound:off -headless -commands 'b 1100;c;savemem sierdec 1100 3000;q' ; \
		truncate -r sier sierdec ; \
		cmp sier sierdec ; \
	else \
		echo exo failed, skipping 1>&2 ; \
		cp sier \!BOOT ; \
		echo "\$$.!BOOT FFFF1100 FFFF1100" >\!BOOT.inf ; \
		${BBCIM} -a sier.ssd '!BOOT' ; \
		${BBCIM} -boot sier.ssd RUN  ; \
	fi

coords.s: rotate.py
	${PYTHON} rotate.py >coords.s

inc.s: inc.pl
	${PERL} inc.pl >inc.s

mem: coords.s inc.s sier.s clear.pl Makefile
	${BEEBJIT} -h >/dev/null 2>&1 || echo 
	${BEEBASM} -i sier.s -do mem.ssd -boot sier -D clear_mode=0 -v >mem.txt
	${BEEBJIT} -master -debug -autoboot -0 mem.ssd -opt sound:off -headless -commands 'breakat 100000000;c;savemem siermem3000 8000 2800;savemem siermem5800 a800 2800;q'
	${PERL} clear.pl 3000 25600 <siermem3000 >clear3000.s
	${PERL} clear.pl 5800 25600 <siermem5800 >clear5800.s
	${BEEBASM} -i cleartest.s -do cleartest.ssd -boot clrtest
	${BEEBJIT} -debug -autoboot -0 cleartest.ssd -opt sound:off -headless -commands 'b 0;c;savemem siermem3000.2 3000 2800;savemem siermem5800.2 5800 2800;q'
	${PERL} -pe 's/[^\x00]/\xff/g' siermem3000|cmp siermem3000.2
	${PERL} -pe 's/[^\x00]/\xff/g' siermem5800|cmp siermem5800.2
	touch mem

bench:	sier.ssd bench.pl
	perl bench.pl <out.txt
