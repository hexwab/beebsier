	ORG $1100
	GUARD $3000

;; tweakables

;; 1x1 pixels, every other scanline blank (fastest) 
; doubleheight=0

;; 1x2 pixels (slowest, brightest, blockiest)
; doubleheight=1

;; alternately 1x1 and 1x2 pixels (best-looking)
doubleheight=2

;; how many points to draw, *2. smaller is faster
; points are split into "early" (no readback) and "late"
;  10fps 
;npoints=844
;enpoints=240

;  12.5fps 
;npoints=780
;enpoints=310

;  12.5fps !
npoints=692
enpoints=128

;; 0=no clearing; 1=vague (smallest); 2=precise (fastest)
clear_mode=?2

oswrch = $ffee
osbyte = $fff4
osword = $fff1

; we would like to put tables below $2000 so that on Elk
; with turbo board (not MRB in turbo mode!) accesses are at 2MHz
linetabxlo=$400
linetabxhi=$500
randtab=$600
inc0_copy=$800
inc1_copy=$900
inc2_copy=$a00
inc3_copy=$b00
inctab=$c00
inctab2=$300

MACRO _stazp addr
	equb $85, addr-zpoff
ENDMACRO
MACRO _deczp addr
	equb $c6, addr-zpoff
ENDMACRO
MACRO _inczp addr
	equb $e6, addr-zpoff
ENDMACRO
MACRO _ldazp addr
	equb $a5, addr-zpoff
ENDMACRO
MACRO _eorzp addr
	equb $45, addr-zpoff
ENDMACRO
MACRO _adczpX addr
	equb $75, addr-zpoff
ENDMACRO

MACRO clr x, y
	sta addr + y*linelen + x, X
ENDMACRO


MACRO _clear addr
{
	; 34088 cycles
	ldx #$3e+doubleheight
.clearloop1
	clr $80, 1
	clr $80, 2
	clr $80, 3
	clr $80, 4
	clr $80, 5
	clr $c0, 11
	clr $c0, 12
	clr $c0, 13
	clr $c0, 14
	clr $c0, 15
	clr $c0, 16
	clr $100, 22
	clr $100, 23
	clr $100, 24
	clr $100, 25
	clr $100, 26
	clr $100, 27
	clr $100, 28
	clr $100, 29
	dex
IF doubleheight=0
	dex
ENDIF
	bpl clearloop1
	ldx #$7e+doubleheight
.clearloop1a
	clr $60, 6
	clr $60, 7
	clr $60, 8
	clr $60, 9
	clr $60, 10
	clr $40, 11
	clr $40, 12
	clr $40, 13
	clr $40, 14
	clr $40, 15
	clr $40, 16
	clr $60, 31
	dex
IF doubleheight=0
	dex
ENDIF
	bpl clearloop1a
	ldx #0
.clearloop1b
	clr $20, 17
	clr $20, 18
	clr $20, 19
	clr $20, 20
	clr $20, 21
	clr $00, 22
	clr $00, 23
	clr $00, 24
	clr $00, 25
	clr $00, 26
	clr $00, 27
	clr $00, 28
	clr $00, 29
	clr $20, 30
	dex
IF doubleheight=0
	dex
ENDIF
	bne clearloop1b
}
ENDMACRO

MACRO _fullclear addr
{
	ldx #0
.loop
	FOR i,addr,addr+$27ff,256
	sta i,X
	NEXT
	inx
	bne loop
}
ENDMACRO
	
zp=0
scrstart=$5800
scrstart2=$3000
linelen=$140	
	;; 0..127
.start
	sei
.initscreen
	lda #0
	tax
.l
	sta $3000,X
	inx
	bne l
	inc l+2
	bpl l
	lda #133
	ldx #5
	ldy #0
	jsr osbyte
	tya
	bpl noshadow
	lda #114
	ldx #1
	ldy #0
	jsr osbyte
.noshadow	
	lda #22
	jsr oswrch
	lda #5
	jsr oswrch
	lda #10 ; cursor off
	sta $fe00
	sta $fe01
	; on electron software cursor will never be drawn

	; if interlace is off add an extra row
	; this gives us at least 40000 cycles per frame
	lda $291
	beq interlaced
	lda #5
	sta $fe00
	lda #1
	sta $fe01
.interlaced

IF clear_mode=0
	lda #4
	sta $fe30
	lda #0
	tax
.k
	sta $cf00,X
	inx
	bne k
	dec k+2
	bmi k
ENDIF

	lda #0
        tax
        inx
        jsr osbyte
	txa
	bne notelk
.elk
	lda #scrstart2 DIV&200
	sta flip1+1
	lda #scrstart DIV&200
	sta flip2+1
	lda #$03 ; fe01->fe03
	sta flip1+3
	sta flip2+3
	lda #$14 ; #2->#$14
	sta vsync+1
	lda #5 ; fe4d->fe05
	sta vsync+3
	lda #0 ; fe4d->fe00
	sta vsync+6
.notelk

	ldx #$ff
	txs
	inx
	jsr fillrand2

	; this makes inc compress better
.incfixup
	txa
	clc
	adc inc0,X
	sta inc0_copy,X
	txa
	clc
	adc inc1,X
	sta inc1_copy,X
	txa
	clc
	adc inc2,X
	sta inc2_copy,X
	txa
	clc
	adc inc3,X
	sta inc3_copy,X
        txa
        and #3
        clc
        adc #>inc0_copy
        sta inctab,X
	inx
	bne incfixup

.makelinetabx
	txa
	asl A
	and #$f8
	sta linetabxlo,X
	lda #0
	adc #0
	sta linetabxhi,X
	inx
	bne makelinetabx

.makeinctab2
	lda #8
	sta inctab2,X
	lsr A
	inx
	sta inctab2,X
	lsr A
	inx
	sta inctab2,X
	lsr A
	inx
	sta inctab2,X
	lsr A
	inx
	bne makeinctab2

.zpcopy
	ldx #zpend-zpstart
.zpcopyloop
	lda zpstart-1,X
	sta $00ff,X
	dex
	bne zpcopyloop

.mainloop
	;jsr $ffe0
.clear1
IF clear_mode=2
	lda #0
	INCLUDE "clear3000.s"
ELIF clear_mode=1
	lda #0
	_fullclear scrstart2
ELIF clear_mode=0
	jsr copy
	lda #0
	_fullclear scrstart2
ENDIF
	jsr update
.flip1
	ldx #12
	stx $fe00
	ldx #scrstart2 DIV&800
	stx $fe01
	;ldx #$02
	;stx $fe21
	;jsr $ffe0
 	_inczp ytabptr+2
 	_inczp ytabptr2+2
IF 1;clear_mode<>0
 	_inczp eytabptr+2
 	_inczp eytabptr2+2
ENDIF
IF clear_mode=2
 	lda #0
	INCLUDE "clear5800.s"
ELIF clear_mode=1
 	lda #0
	_fullclear scrstart
ELIF clear_mode=0
	jsr copy
	lda #0
	_fullclear scrstart
ENDIF
	jsr update
.flip2
	ldx #12
	stx $fe00
	ldx #scrstart DIV&800
	stx $fe01
	;ldx #$05
	;stx $fe21
	;jsr $ffe0
 	_deczp ytabptr+2
 	_deczp ytabptr2+2
IF 1;clear_mode<>0
 	_deczp eytabptr+2
 	_deczp eytabptr2+2
ENDIF
	jmp mainloop

.update
	;jsr $ffe0
	lda #1+npoints/128
	_stazp counthi
	lda #127-(npoints MOD128)
	_stazp rand+1
	lda #1+enpoints/128
	_stazp ecounthi
	lda #127-(enpoints MOD128)
	_stazp erand+1

	;lda #<npoints
	;_stazp countlo
.doframe
	_inczp frame
	_ldazp frame
	and #$3f
	bne nopal
	jsr pal
	_ldazp frame
.nopal
	and #$3f
	tax
	lda xcoordtab0,X
	_stazp xcoords
	asl A
IF 0;clear_mode=0
	_stazp xpos+1
ELSE
	_stazp expos+1
ENDIF
	lda xcoordtab1,X
	_stazp xcoords+1
	lda xcoordtab2,X
	_stazp xcoords+2
	;lda xcoordtab3,X
	;_stazp xcoords+3
	lda ycoordtab0,X
	_stazp ycoords
	asl A
IF 0; clear_mode=0
	_stazp ypos+1
ELSE
	_stazp eypos+1
ENDIF
	lda ycoordtab1,X
	_stazp ycoords+1
	lda ycoordtab2,X
	_stazp ycoords+2
	;lda ycoordtab3,X
	;_stazp ycoords+3
	ldy #16
	jmp zp

.palettes
	;equb $13, $26, $45, $23, $46, $15, $56, $42
;	equb 1, 2, 4, 2, 4, 1, 5, 4
;	equb 3, 6, 5, 3, 6, 5, 6, 2
	equb 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5
	equb 2, 3, 4, 5, 6, 3, 4, 5, 6, 5, 6, 2, 5, 6, 6, 2
.pal
	jsr rand8
	bmi norev
	 ; reverse
	tax
	lda doframe
	eor #$20
	sta doframe
	;txa
.norev
	; random palette
	inc palnum
	lda palnum
	and #$0f
	tax
 	lda palettes,X
	ora #$20
	jsr writepal
	lda palettes+16,X
	ora #$80
.writepal
	eor #7
	sta $fe21
	ora #$10
	sta $fe21
	ora #$40
	sta $fe21
	and #$ef
	sta $fe21
	rts
.palnum
	equb 0
;; 	sta paltmp+1
;; 	lda palettes,X
;; 	_deczp palblock
;; 	jsr writepal
;; .paltmp
;; 	ldx #$00
;; 	lda palettes+8,X
;; 	_inczp palblock
;; .writepal
;; 	_stazp palblock+1
;;         ldx #<(palblock-zpoff)
;;         ldy #>(palblock-zpoff)
;; 	lda #12
;; 	jmp osword

IF clear_mode=0
.copy
	lda #$30
	sta j+2
	lda #$80
	sta j+5
	sta j+8
	ldx #0
.j
	lda $3000,X
	ora $8000,X
	sta $8000,X
	inx
	bne j
	inc j+8
	inc j+5
	inc j+2
	bpl j
	rts
ENDIF

	; via https://www.codebase64.org/doku.php?id=base:ax_tinyrand8
.rand8
b1=*+1
	lda #31
	asl A
a1=*+1
	eor #53
	sta b1
	adc a1
	sta a1
	rts

.fillrand2
	jsr fillrand
	inc randptr+2
.fillrand
.randloop
	jsr rand8
	and #3
.randptr
	sta randtab,X
	inx
	bne randloop
	rts

.zpstart
zpoff = zpstart-zp

.trace1
.early

IF 1;clear_mode<>0
.eloop
	; unroll a
.erand	ldx randtab,Y
	;_stazp rand+1

.eypos	lda #0
	lsr A
	;clc
	_adczpX ycoords
	_stazp eypos2+1
	tay
.expos	lda #0
	lsr A
	;clc
	_adczpX xcoords
	_stazp expos2+1
	tax

.ecalcscreenaddr
	lda linetabxlo,X
	; C clear
	adc linetabylo,Y
	_stazp eptr+1
	lda linetabxhi,X
.eytabptr
	adc linetabyhi,Y
	_stazp eptr+2
	; subpixel
	lda inctab2,X
	;_ldazpX inctab2
.eptr
	sta $ee00

.eloop2
	; unroll b
.erand2	ldx randtab,Y
	;_stazp rand+1

.eypos2	lda #0
	lsr A
	;clc
	_adczpX ycoords
	_stazp eypos+1
	tay
.expos2	lda #0
	lsr A
	;clc
	_adczpX xcoords
	_stazp expos+1
	tax

.ecalcscreenaddr2
	lda linetabxlo,X
	; C clear
	adc linetabylo,Y
	_stazp eptr2+1
	;_stazp eytmp+1
	lda linetabxhi,X
.eytabptr2
	adc linetabyhi,Y
	_stazp eptr2+2
	; subpixel
	lda inctab2,X
;.eytmp
;	ldy #$ee
;.eptr2
;	sta $ee00,Y
;	iny
;	sta (eptr2-zpoff+1),Y

.eptr2
	sta $eeee

	_inczp erand+1
	bpl eloop
	lda #0
	_stazp erand+1
	;_stazp rand2+1
	_deczp ecounthi
	bne eloop

	_ldazp expos+1
	_stazp xpos+1
	_ldazp eypos+1
	_stazp ypos+1
ENDIF	
	ldy #18
	
.trace2
.loop
	; unroll a
.rand	ldx randtab,Y
	;_stazp rand+1

.ypos	lda #0
	lsr A
	;clc
	_adczpX ycoords
	_stazp ypos2+1
	tay
.xpos	lda #0
	lsr A
	;clc
	_adczpX xcoords
	_stazp xpos2+1
	tax

.calcscreenaddr
	; subpixel
	lda inctab,X
	_stazp incptr+2
	lda linetabxlo,X
	; C clear
	adc linetabylo,Y
	_stazp ytmp+1
	;lda #0
	lda linetabxhi,X
.ytabptr
	adc linetabyhi,Y
	_stazp ptr+2
	;;_stazp ptr2+2
	;;_stazp ptr3+2
.ytmp
	ldy #$ee
.ptr
	ldx $ee00,Y
.incptr
	lda inc0,X
;.ptr2
	sta (ptr-zpoff+1),Y
	;sta $ee00,Y
IF doubleheight
;.ptr3
	;sta $ee01,Y
	iny
	sta (ptr-zpoff+1),Y
ENDIF


	; unroll b
.rand2	ldx randtab,Y
	_stazp rand2+1

.ypos2	lda #0
	lsr A
	;clc
	_adczpX ycoords
	_stazp ypos+1
	tay
.xpos2	lda #0
	lsr A
	;clc
	_adczpX xcoords
	_stazp xpos+1
	tax

.calcscreenaddr2
	; subpixel
	lda inctab,X
	_stazp incptr2+2
	lda linetabxlo,X
	; C clear
	adc linetabylo,Y
	_stazp ytmp2+1
	;lda #0
	lda linetabxhi,X
.ytabptr2
	adc linetabyhi,Y
	_stazp ptr2+2
.ytmp2
	ldy #$ee
.ptr2
	ldx $ee00,Y
.incptr2
	lda inc0,X
	sta (ptr2-zpoff+1),Y
IF doubleheight=1
	iny
	sta (ptr2-zpoff+1),Y
ENDIF

	_inczp rand+1
	bpl loop
	lda #0
	_stazp rand+1
	;_stazp rand2+1
	_deczp counthi
	bne loop
IF 0;clear_mode=0
	rts
ENDIF
.trace3
.vsync
	lda #2
	sta $fe4d ; ack
.vsyncloop
	bit $fe4d
	beq vsyncloop
.trace4
	rts
.xcoords
	equb 0
	equb 0
	equb 0
	equb xcoord3
.ycoords
	equb 0
	equb 0
	equb 0
	equb ycoord3
;.countlo
;	equb 0
.counthi
	equb 0
;.ecountlo
;	equb 0
.ecounthi
	equb 0
.frame
	equb 0
;.palblock
;	equb 2
;	equd 0

.zpend

PRINT "zpsize=",~(zpend-zpstart)
	align $100
IF 0 ; 256 lines
.linetabylo
	for i,0,255
	equb (scrstart+(i AND7)+((i DIV8)*linelen))MOD256
	next
.linetabyhi
	for i,0,255
	equb (scrstart+(i AND7)+((i DIV8)*linelen))DIV256
	next
ELSE ; 128 lines
.linetabyhi
	for i,0,127
	equb (scrstart2+(i AND3)*2+((i DIV4)*linelen))DIV256
	next
.linetabylo
	for i,0,127
	equb (scrstart+(i AND3)*2+((i DIV4)*linelen))MOD256
	next
.linetabyhi2
	for i,0,127
	equb (scrstart+(i AND3)*2+((i DIV4)*linelen))DIV256
	next
ENDIF
	INCLUDE "coords.s"
	
;; .inctab
;; 	for i,0,63
;; 	equb >inc0,>inc1,>inc2,>inc3
;; 	next
	align $100
	INCLUDE "inc.s"
.end
;; .linetabxlo
;; 	for i,0,63
;; 	equb ((i*8))MOD256
;; 	equb ((i*8))MOD256
;; 	equb ((i*8))MOD256
;; 	equb ((i*8))MOD256
;; 	next
;; .linetabxhi
;; 	for i,0,63
;; 	equb ((i*8))DIV256
;; 	equb ((i*8))DIV256
;; 	equb ((i*8))DIV256
;; 	equb ((i*8))DIV256
;; 	next
;.randtab
; calc at runtime for size: random data compresses poorly
;	for i,0,511
;	equb RND(4)
;	next
	SAVE "sier",start,end
