	.include "font8x16.inc"
	.include "font6x8.inc"

;------------------------------------------------------------
;	Mapeado de Video (bloques 0,1,2,3) a páginas 1,2,3,4
;------------------------------------------------------------

vmap:	pha
	txa
	pha
	ldx	#3
	lda	PAGE4
	stx	PAGE4	; Cambiamos pag 4 a bloque 3
	sta	$8403	; Guardamos valores anteriores (ahora al final del video)
	dex
	lda	PAGE3
	stx	PAGE3
	sta	$8402
	dex
	lda	PAGE2
	stx	PAGE2
	sta	$8401
	dex
	lda	PAGE1
	stx	PAGE1
	sta	$8400
	pla
	tax
	pla
	rts

vunmap:	; Recupera mapeado anterior
	lda	$8400
	sta	PAGE1
	lda	$8401
	sta	PAGE2
	lda	$8402
	sta	PAGE3
	lda	$8403
	sta	PAGE4
	rts
;------------------------------------------------------------
;	Borra la pantalla
;------------------------------------------------------------

cfondo:	lda	#1
	bit	STAT2
	beq	cfon1
	lda	COLOR	;color
	lsr
	lsr
	lsr
	lsr
	sta	tmp1
	lda	COLOR	;color
	and	#$F0
	ora	tmp1
	sta	tmp1
	rts
cfon1:	lda	#0
	sta	tmp1
	rts

	.export cls
cls:	jsr	vmap
	jsr	cfondo
	lda	#100
	sta	tmp5
	lda	#$20	;pagina 1
	sta	ptr4+1
	lda	#0
	sta	ptr4
	tay
	lda	tmp1
cls1:	sta	(ptr4),y
	iny
	bne	cls1
	inc	ptr4+1
	dec	tmp5
	bne	cls1
	sty	tposx
	sty	tposy
	beq	vunmap	;incondicional

;------------------------------------------------------------
;   Imprime caracter en posición (tposx,tposy)
;    en unidades de caracteres
;------------------------------------------------------------
	.export gputchpos
	; tposx: pos X/8
	; tposy: pos Y/16
	; A:	ASCII
gputchpos:
	sec
	sbc	#32
	pha
	lda	tposy	; Y*4 (*256)
	asl	
	asl
	clc
	adc	#$20	;pagina 1
	sta	ptr5+1
	lda	#1
	bit	STAT2	;vmod
	bne	gputchpos4
	lda	tposx	; ptr5=destino
	sta	ptr5

	lda	#0	; ptr4=origen
	sta	ptr4+1
	pla
	asl
	rol	ptr4+1
	asl
	rol	ptr4+1
	asl
	rol	ptr4+1
	asl
	rol	ptr4+1
	clc
	adc	#<font8x16
	sta	ptr4
	lda	ptr4+1
	adc	#>font8x16
	sta	ptr4+1

	ldy	#0
gpt1:	lda	(ptr4),y
	sta	(ptr5),y
	iny	
	lda	#63
	clc
	adc	ptr5
	sta	ptr5
	bcc	gpt2
	inc	ptr5+1
gpt2:	cpy	#16
	bne	gpt1
	rts

;----- versión para modo color
gputchpos4:
	lda	tposx	; ptr5=destino
	asl
	adc	tposx	; X*3
	sta	ptr5

	lda	#0	; ptr4=origen
	sta	ptr4+1
	pla
	asl
	rol	ptr4+1
	asl
	rol	ptr4+1
	asl
	rol	ptr4+1
	clc
	adc	#<font6x8
	sta	ptr4
	lda	ptr4+1
	adc	#>font6x8
	sta	ptr4+1

	;jsr	setcol4
setcol4:
	lda	COLOR	
	sta	1
	lsr
	lsr
	lsr
	lsr
	sta	0
	lda	COLOR	
	and	#$F0
	ora	0
	sta	0
	lda	COLOR	
	asl
	asl
	asl
	asl
	sta	2
	sta	3
	lda	COLOR	
	and	#$0F
	ora	3
	sta	3
	lda	0
	and	#$0F
	ora	2
	sta	2

	txa
	pha

	ldy	#0
gpt3:	lda	(ptr4),y
	sta	tmp5
	rol
	rol	tmp5
	rol
	rol	tmp5
	lda	tmp5
	and	#3
	tax
	lda	0,x
	sta	(ptr5),y
	iny

	lda	tmp5
	rol
	rol	tmp5
	rol
	rol	tmp5
	lda	tmp5
	and	#3
	tax
	lda	0,x
	sta	(ptr5),y
	iny

	lda	tmp5
	rol
	rol	tmp5
	rol
	rol	tmp5
	lda	tmp5
	and	#3
	tax
	lda	0,x
	sta	(ptr5),y
	dey

	lda	#127
	clc
	adc	ptr5
	sta	ptr5
	lda	ptr5+1
	adc	#0
	sta	ptr5+1

	cpy	#8
	bne	gpt3

	pla
	tax

	rts

;------------------------------------------------------------
; EMULACION de TERMINAL
;------------------------------------------------------------
	.export gputch		; Caracteres especiales interpretados
gputch:	jsr	vmap
	cmp	#10		; NL
	bne	gptch1
	lda	#0
	sta	tposx
	inc	tposy
	lda	tposy		; Scrool?
	cmp	#25
	beq	scrl0
	jmp	vunmap
	;----------------------
	; scrool
	;----------------------
scrl0:	dec	tposy
	lda	#$20	;vpag
	sta	ptr4+1
	clc
	adc	#4
	sta	ptr5+1
	lda	#0
	sta	ptr5
	sta	ptr4
	lda	#96
	sta	tmp5
	ldy	#0
scrl1:	lda	(ptr5),y
	sta	(ptr4),y
	iny
	bne	scrl1
	inc	ptr5+1
	inc	ptr4+1
	dec	tmp5
	bne	scrl1
	lda	#4
	sta	tmp5
	jsr	cfondo
	ldy	#0
scrl2:	sta	(ptr4),y
	iny
	bne	scrl2
	inc	ptr4+1
	dec	tmp5
	bne	scrl2
	jmp	vunmap	;rts

gptch1:	cmp	#13		; CR
	bne	gptch2
	lda	#0
	sta	tposx
	jmp	vunmap	;rts
gptch2:	cmp	#8		; backspace
	bne	gptch3
	dec	tposx
	bpl	retg1
	inc	tposx
	jmp	vunmap	;rts
gptch3:	cmp	#9		; Tab
	bne	gptch4
	lda	#7
	clc
	adc	tposx
	and	#$F8
	sta	tposx
	jmp	vunmap	;rts

gptch4:
	pha			; Caracteres normales (imprimibles)
	lda	#1
	bit	STAT2		;vmod
	beq	gptch8
	pla
	ldy	#41
	cpy	tposx
	bcs	gptch9
	jmp	vunmap	;rts
gptch8:	pla
	bit	tposx		; Bit 6 en 1 => fuera de pantalla
	bvs	retg1
gptch9:	jsr	gputchpos
	inc	tposx
retg1:	jmp	vunmap	;rts


	.export gputs
	; X offset desde msgs
retg2:	rts
gputs:	lda	msgs,x
	beq	retg2
	jsr	gputch
	inx
	jmp	gputs


;--------------------------------------
; Setpixel, clrpixel, tglpixel
;	tmp1,tmp2: X
;	tmp3,tmp4: Y

	.export setpixel, clrpixel, tglpixel


calpxaddr:
	jsr	vmap
	lda	#$80
	sta	tmp5
	lda	#7	; tmp5=(0x80>>(x&7))
	and	tmp1
	beq	spx2
	tay
spx1:	lsr	tmp5
	dey
	bne	spx1
spx2:	lsr	tmp1+1	; X/8
	ror	tmp1
	lsr	tmp1+1
	ror	tmp1
	lsr	tmp1+1
	ror	tmp1

	ror	tmp3+1	; Y*64
	ror	tmp3
	ror	tmp3+1
	ror	tmp3
	ror	tmp3+1
	lda	#$C0
	and	tmp3+1	; intercambio H <-> L: ahora tmp3+1 es LSB
;	sta	tmp3+1

	clc
;	lda	tmp3+1	; tmp1= Y*64 + X/8 +vpag*256
	adc	tmp1
	sta	tmp1
	lda	tmp3	; MSB
	adc	tmp1+1
	adc	#$20	; vpag
	sta	tmp1+1
	ldy	#0
	lda	(tmp1),y
	rts

setpixel:
	jsr	calpxaddr
	ora	tmp5
	sta	(tmp1),y
	jmp	vunmap
clrpixel:
	jsr	calpxaddr
	ora	tmp5
	eor	tmp5
	sta	(tmp1),y
	jmp	vunmap
tglpixel:
	jsr	calpxaddr
	eor	tmp5
	sta	(tmp1),y
	jmp	vunmap

;------------------------------------------------
; Putpixel para modo 4bpp
; tmp1: X
; tmp2: Y
; tmp3: color
	.export putpixel4
putpixel4:
	jsr	vmap
	lda	#$0F
	and	tmp3
	sta	tmp3
	lda #0		; tmp2:ptr1 = Y*128 (tmp2: MSB)
	clc
	ror	tmp2	
	ror
	sta	ptr1

	lda	tmp1	; A=X/2
	lsr
	clc
	adc	ptr1	; ptr1 = vpag*256 + Y*128 + X/2
	sta	ptr1
	lda	tmp2
	adc	#$20	;vpag
	sta	ptr1+1
	
	ldy	#0
	lsr	tmp1
	bcs	ppx41
	lda	#$0F
	and	(ptr1),y
	asl	tmp3
	asl	tmp3
	asl	tmp3
	asl	tmp3
	ora	tmp3
	sta	(ptr1),y
	jmp	vunmap
ppx41:	lda	(ptr1),y
	and	#$F0
	ora	tmp3
	sta	(ptr1),y
	jmp	vunmap

