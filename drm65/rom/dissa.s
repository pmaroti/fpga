; ------------------------------------------------------------------------
; 			Disassemble a single OP-code
; ------------------------------------------------------------------------
	.export	dissaOP
dissaOP:	
	lda	ptr1+1		; print address
	jsr	prthex
	lda	ptr1
	jsr	prthex
	lda	#' '
	jsr	cout	
	ldy	#0
	lda	(ptr1),y	; get OP-code
	tax
	jsr	prthex	; print first byte of instruction
	lda	#' '
	jsr	cout	

	lda	#$40
	and	optbl1,x
	beq	dissa1
	iny
	lda	(ptr1),y
	jsr	prthex	; print second byte
	lda	#' '
	jsr	cout
dissa1:	lda	optbl1,x
	bpl	dissa2
	iny
	lda	(ptr1),y
	jsr	prthex	; print third byte
dissa2:	lda	#9	; TAB
	jsr	cout
	lda	optbl2,x	; offset to mnemonic
	tax

	ldy	#3
dissa25:
	lda	nmtbl,x
	jsr	cout
	inx
	dey
	bne	dissa25

	lda	#' '
	jsr	cout

	ldy	#0
	lda	(ptr1),y
	tax
	lda	optbl1,x
	and	#$3F		; offset to address mode
	tax

adml1:	lda	admtab,x
	beq	adml9
	cmp	#'x'
	bne	adml2
	iny
	iny
	lda	(ptr1),y
	jsr	prthex
	dey	
	lda	(ptr1),y
	jsr	prthex
	iny
	jmp	adml5
adml2:	cmp	#'h'
	bne	adml3
	iny
	lda	(ptr1),y
	jsr	prthex
	jmp	adml5
adml3:	cmp	#'r'
	bne	adml4
	inc	ptr1
	bne	adml31
	inc	ptr1+1
adml31:	lda	(ptr1),y
	sec
	bpl	adml35
	adc	ptr1
	pha
	lda	#$FF
adml33:	adc	ptr1+1
	jsr	prthex
	pla
	jsr	prthex
	jmp	adml5
adml35: adc	ptr1
	pha
	lda	#$00
	jmp	adml33	

adml4:	jsr	cout
adml5:	inx
	bne	adml1

adml9:	sec			; update pointer
	tya
	adc	ptr1
	sta	ptr1
	lda	ptr1+1
	adc	#0
	sta	ptr1+1
	rts

admtab:	
admAcc:	.byte "A"
admImp:	.byte 0
admImm:	.byte "#"
admZP:	.byte "h",0
admZPX:	.byte "h,X",0
admZPY:	.byte "h,Y",0
admIndX:	.byte "(h,X)",0
admIndY:	.byte "(h),Y",0
admRel:	.byte "r",0
admAbs:	.byte "x",0
admAbsX:	.byte "x,X",0
admAbsY:	.byte "x,Y",0
admInd:	.byte"(x)",0	

optbl1:
	.byte $00+admImp-admtab, $40+admIndX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admZP-admtab
	.byte $40+admZP-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admImm-admtab, $00+admAcc-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbs-admtab, $C0+admAbs-admtab
	.byte $00+admImp-admtab, $40+admRel-admtab, $40+admIndY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZPX-admtab, $40+admZPX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsX-admtab
	.byte $C0+admAbsX-admtab, $00+admImp-admtab, $C0+admAbs-admtab
	.byte $40+admIndX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZP-admtab, $40+admZP-admtab, $40+admZP-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admImm-admtab
	.byte $00+admAcc-admtab, $00+admImp-admtab, $C0+admAbs-admtab
	.byte $C0+admAbs-admtab, $C0+admAbs-admtab, $00+admImp-admtab
	.byte $40+admRel-admtab, $40+admIndY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admZPX-admtab
	.byte $40+admZPX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $C0+admAbsY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsX-admtab, $C0+admAbsX-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admIndX-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZP-admtab, $40+admZP-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admImm-admtab, $00+admAcc-admtab
	.byte $00+admImp-admtab, $C0+admAbs-admtab, $C0+admAbs-admtab
	.byte $C0+admAbs-admtab, $00+admImp-admtab, $40+admRel-admtab
	.byte $40+admIndY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admZPX-admtab, $40+admZPX-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $C0+admAbsX-admtab, $C0+admAbsX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admIndX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admZP-admtab
	.byte $40+admZP-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admImm-admtab, $00+admAcc-admtab, $00+admImp-admtab
	.byte $C0+admInd-admtab, $C0+admAbs-admtab, $C0+admAbs-admtab
	.byte $00+admImp-admtab, $40+admRel-admtab, $40+admIndY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZPX-admtab, $40+admZPX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsX-admtab
	.byte $C0+admAbsX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admIndX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZP-admtab, $40+admZP-admtab, $40+admZP-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbs-admtab
	.byte $C0+admAbs-admtab, $C0+admAbs-admtab, $00+admImp-admtab
	.byte $40+admRel-admtab, $40+admIndY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admZPX-admtab, $40+admZPX-admtab
	.byte $40+admZPY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $C0+admAbsY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admImm-admtab, $40+admIndX-admtab
	.byte $40+admImm-admtab, $00+admImp-admtab, $40+admZP-admtab
	.byte $40+admZP-admtab, $40+admZP-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admImm-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbs-admtab, $C0+admAbs-admtab
	.byte $C0+admAbs-admtab, $00+admImp-admtab, $40+admRel-admtab
	.byte $40+admIndY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZPX-admtab, $40+admZPX-admtab, $40+admZPY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsX-admtab
	.byte $C0+admAbsX-admtab, $C0+admAbsY-admtab, $00+admImp-admtab
	.byte $40+admImm-admtab, $40+admIndX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $40+admZP-admtab, $40+admZP-admtab
	.byte $40+admZP-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admImm-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $C0+admAbs-admtab, $C0+admAbs-admtab, $C0+admAbs-admtab
	.byte $00+admImp-admtab, $40+admRel-admtab, $40+admIndY-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZPX-admtab, $40+admZPX-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbsX-admtab
	.byte $C0+admAbsX-admtab, $00+admImp-admtab, $40+admImm-admtab
	.byte $40+admIndX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $40+admZP-admtab, $40+admZP-admtab, $40+admZP-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admImm-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $C0+admAbs-admtab
	.byte $C0+admAbs-admtab, $C0+admAbs-admtab, $00+admImp-admtab
	.byte $40+admRel-admtab, $40+admIndY-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $00+admImp-admtab, $40+admZPX-admtab
	.byte $40+admZPX-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $C0+admAbsY-admtab, $00+admImp-admtab, $00+admImp-admtab
	.byte $00+admImp-admtab, $C0+admAbsX-admtab, $C0+admAbsX-admtab
	.byte $00+admImp-admtab
optbl2:
	.byte $1E,$66,$A8,$A8,$A8,$66,$06,$A8,$6C,$66,$06,$A8,$A8,$66,$06,$A8
	.byte $1B,$66,$A8,$A8,$A8,$66,$06,$A8,$27,$66,$A8,$A8,$A8,$66,$06,$A8
	.byte $54,$03,$A8,$A8,$12,$03,$75,$A8,$72,$03,$75,$A8,$12,$03,$75,$A8
	.byte $15,$03,$A8,$A8,$A8,$03,$75,$A8,$8D,$03,$A8,$A8,$A8,$03,$75,$A8
	.byte $7B,$4B,$A8,$A8,$A8,$4B,$63,$A8,$69,$4B,$63,$A8,$51,$4B,$63,$A8
	.byte $21,$4B,$A8,$A8,$A8,$4B,$63,$A8,$2D,$4B,$A8,$A8,$A8,$4B,$63,$A8
	.byte $7E,$00,$A8,$A8,$A8,$00,$78,$A8,$6F,$00,$78,$A8,$51,$00,$78,$A8
	.byte $24,$00,$A8,$A8,$A8,$00,$78,$A8,$93,$00,$A8,$A8,$A8,$00,$78,$A8
	.byte $A8,$84,$A8,$A8,$8A,$84,$87,$A8,$42,$A8,$9C,$A8,$8A,$84,$87,$A8
	.byte $09,$84,$A8,$A8,$8A,$84,$87,$A8,$9F,$84,$A5,$A8,$A8,$84,$A8,$A8
	.byte $60,$57,$5D,$A8,$60,$57,$5D,$A8,$99,$57,$96,$A8,$60,$57,$5D,$A8
	.byte $0C,$57,$A8,$A8,$60,$57,$5D,$A8,$30,$57,$A2,$A8,$60,$57,$5D,$A8
	.byte $39,$33,$A8,$A8,$39,$33,$3C,$A8,$48,$33,$3F,$A8,$39,$33,$3C,$A8
	.byte $18,$33,$A8,$A8,$A8,$33,$3C,$A8,$2A,$33,$A8,$A8,$A8,$33,$3C,$A8
	.byte $36,$81,$A8,$A8,$36,$81,$4E,$A8,$45,$81,$5A,$A8,$36,$81,$4E,$A8
	.byte $0F,$81,$A8,$A8,$A8,$81,$4E,$A8,$90,$81,$A8,$A8,$A8,$81,$4E,$A8
nmtbl:
	.byte "ADC","AND","ASL","BCC","BCS","BEQ","BIT","BMI"
	.byte "BNE","BPL","BRK","BVC","BVS","CLC","CLD","CLI"
	.byte "CLV","CMP","CPX","CPY","DEC","DEX","DEY","INX"
	.byte "INY","EOR","INC","JMP","JSR","LDA","NOP","LDX"
	.byte "LDY","LSR","ORA","PHA","PHP","PLA","PLP","ROL"
	.byte "ROR","RTI","RTS","SBC","STA","STX","STY","SEC"
	.byte "SED","SEI","TAX","TAY","TXA","TYA","TSX","TXS"
	.byte "???"
	
