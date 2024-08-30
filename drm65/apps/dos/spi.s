;--------------------------------------------------------------------
;--------------------------------------------------------------------
;				SPI code
;--------------------------------------------------------------------
;--------------------------------------------------------------------

; block transfer (up to 256 bytes), writting
; ptr1 -> origin of data
; Y: number of bytes (1 minimum, 0 means 256 bytes)
; A: modiffied

	.export	spiwr
spiwr:	sty	tmp2
	ldy	#0
spiwr1:	lda	(ptr1),y	
	jsr	spibyte
	iny			
	cpy	tmp2		
	bne	spiwr1		
	rts
	
; block transfer (up to 256 bytes), reading
; ptr1 <- destination of data
; Y: number of bytes (minimum: 2 bytes, 0 means 256 bytes)
; A, X, tmp1: modiffied

	.export	spird
spird:	
	sty	tmp2		
	ldy	#0		
	
spird1:	lda	#$ff
	jsr	spibyte		
	sta	(ptr1),y	
	iny			
	cpy	tmp2		
	bne	spird1		
	rts

