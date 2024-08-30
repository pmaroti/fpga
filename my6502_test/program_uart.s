.segment "CODE"
.org $FF00
reset:
    CLD
    SEI
    LDX #$FF   ; Load X register with 127 (stack starts from top of memory)
    TXS        ; Transfer X to stack pointer

    LDA #$00
    STA $1000           ; ledpin output

reccheck:
    LDA $2000
    BEQ reccheck
    LDA $2001
    STA $1000
    JMP reccheck

.segment "VECTS"
.org $FFFA
	.word	reset		; NMI 
	.word	reset		; RESET 
	.word	reset		; IRQ 