	*=$1000-8		; Header for load (8 bytes)
	.byte	$B0,$CA		; Mark
	.word	ini		; load address
	.word	ini		; exec address
	.word	endcode-ini	; Number of bytes

	; Define the I/O registres
	UTXD	=	$E000
	URXD	=	$E000
	USTAT	=	$E001
	CTRL1	=	$E002
	STAT1	=	$E002
	CTRL2	=	$E003
	STAT2	=	$E003
	PINOUT	=	$E004
	PININ	=	$E005
	COLOR	=	$E006
	PWM	=	$E007
	KBD	=	$E007
	PAGE0	=	$E008
	PAGE1	=	$E009
	PAGE2	=	$E00A
	PAGE3	=	$E00B
	PAGE4	=	$E00C
	PAGE5	=	$E00D
	PAGE6	=	$E00E

	; Some ROM variables
	vsynvec = $20C ; Vector IRQ VSYN
	hsynvec	= $20E ; Vector IRQ HSYN

	scankey = $19  ; Scancode from keyboard
	oscank 	= $1A  ; Previous Scancode (0xF0 => key released)

	; Some ROM functions
	cin	= $FF27	; console input
	ugetch	= $FF06	; UART input

	; ---------- OUR program variables --------
	; @ Page Zero
	phase0	= $40
	phase1	= phase0+2
	phase2	= phase1+2
	phase3	= phase2+2
	freq0	= phase3+2
	freq1	= freq0+2
	freq2	= freq1+2
	freq3	= freq2+2
	pwm	= freq3+2	; next pwm level
	oscod	= pwm+1		; old pressed scan code

	;------------ Program code ------------
ini:	
	lda	#<irqH
	sta	hsynvec
	lda	#>irqH
	sta	hsynvec+1

	lda	#0	; all frequencies at 0
	sta	freq0
	sta	freq0+1
	sta	freq1
	sta	freq1+1
	sta	freq2
	sta	freq2+1
	sta	freq3
	sta	freq3+1
	sta	oscod	; no old scan code

	lda	STAT1	; Enable IRQs and clear flags
	and	#$0F
	ora	#$88
	sta	CTRL1

buc1:	lda	scankey
	cmp	oscod	; wait for change
	beq	buc1
	sta	oscod
	lda	oscod
	bmi	buc1	; ignore $E0, $F0's

	ldx	oscank
	cpx	#$F0
	beq	release	
	cmp	#$15	; Q key: quit app
	beq	sig9	
	tax
	lda	keyscan,x
	beq	buc1
	sec
	sbc	#1
	asl
	tax

	ldy	#0	; search for a matching oscillator
buc2:	lda	freq0,y
	cmp	fnotas,x
	bne	sig20
	lda	freq0+1,y
	cmp	fnotas+1,x
	beq	buc1	; already on, ignore
sig20:	iny
	iny
	cpy	#8
	bne	buc2

	ldy	#0	; No matching, start an idle osc
buc25:	lda	freq0,y
	ora	freq0+1,y
	beq	sig2	; idle one
	iny
	iny
	cpy	#8
	bne	buc25
	beq	buc1	; all busy

sig2:	lda	fnotas,x ; start oscillator
	sta	freq0,y
	lda	fnotas+1,x
	sta	freq0+1,y
	jmp	buc1

release:	; key released
	ldx	#0
	stx	oscod
	tax
	lda	keyscan,x
	beq	buc1
	sec
	sbc	#1
	asl
	tax

	ldy	#0	; search for a matching oscillator
buc3:	lda	freq0,y
	cmp	fnotas,x
	bne	sig3
	lda	freq0+1,y
	cmp	fnotas+1,x
	beq	sig4
sig3:	iny
	iny
	cpy	#8
	bne	buc3
	jmp	buc1

sig4:	lda	#0	; stop oscillator
	sta	freq0,y
	sta	freq0+1,y
	jmp	buc1

sig9:	lda	STAT1	; disable IRQ
	and	#7
	sta	CTRL1
	rts

;-----------------------------------------------------
;		    HSYNC IRQ:
;		4 DDS oscillators
;-----------------------------------------------------

irqH:	lda	pwm	; update PWM level
	sta	PWM

	lda	STAT1	; clear IRQ flag
	and	#$0F
	ora	#$80
	sta	CTRL1

	; compute next sample

	clc		; Oscillator 0
	lda	freq0	; phase+=freq
	adc	phase0
	sta	phase0
	lda	freq0+1
	adc	phase0+1
	sta	phase0+1
	bpl	irq1	; out=(phaseH>=0x8000)?~phaseH : phaseH
	eor	#$FF	;   => triangle wave
irq1:	lsr		; out/=2 (range from 0 to 63)
	sta	pwm
	clc		; Oscillator 1
	lda	freq1
	adc	phase1
	sta	phase1
	lda	freq1+1
	adc	phase1+1
	sta	phase1+1
	bpl	irq2
	eor	#$FF
irq2:	lsr
	clc
	adc	pwm
	sta	pwm
	clc		; Oscillator 2
	lda	freq2
	adc	phase2
	sta	phase2
	lda	freq2+1
	adc	phase2+1
	sta	phase2+1
	bpl	irq3
	eor	#$FF
irq3:	lsr
	clc
	adc	pwm
	sta	pwm
	clc		; Oscillator 3
	lda	freq3
	adc	phase3
	sta	phase3
	lda	freq3+1
	adc	phase3+1
	sta	phase3+1
	bpl	irq4
	eor	#$FF
irq4:	lsr
	clc
	adc	pwm
	sta	pwm

	rti

;-----------------------------------------------------
;		    Tables
;-----------------------------------------------------
fnotas:
	.word 544,577,611,647,686,727,770,816,864,916,970,1028
	.word 1089,1154,1222,1295,1372,1453,1540,1631,1728,1831,1940,2055

	SCBAS = $1a
	SCMAX = $61

keyscan:
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,3,4,2,0,0,0
	.byte 0,6,5,0,0,0,0,0,0,0,8,7,0,0,0,0
	.byte 0,12,10,11,9,13,0,0,0,0,0,0,15,14,16,0
	.byte 0,0,0,17,18,19,0,0,0,0,0,0,0,20,21,0
	.byte 0,0,0,0,22,23,0,0,0,0,0,24,0,0,0,0
	.byte 0,1

endcode:

