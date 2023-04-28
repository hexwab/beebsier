	ORG $1100
.start
	lda #22
	jsr $ffee
	lda #1
	jsr $ffee
	lda #$ff
	INCLUDE "clear3000.s"
	INCLUDE "clear5800.s"
	jmp 0
.end

SAVE "clrtest",start,end
