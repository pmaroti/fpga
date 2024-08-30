.segment "CODE"
.org $FF00
reset:
    CLD
    SEI
    LDX #$FF   ; Load X register with 127 (stack starts from top of memory)
    TXS        ; Transfer X to stack pointer

    LDA #$00
lp:    
    STA $1000           ; ledpin output
    ADC #1              ; increment A

    LDX #200            ; sleep 200*1ms
lp2:
    JSR sleep1ms
    DEX
    BNE lp2

    JMP lp

sleep1ms:
    PHA     ;3
    TYA     ;2
    PHA     ;3
    TXA     ;2
    PHA     ;3

    LDX #71    ;2
    ;sum15
lsleep2:    
    LDY #93    ;2
lsleep1:
    DEY     ;2
    BNE lsleep1 ;2/3
    ; sum15, 2+4*Y + 2
    DEX     ;2
    BNE lsleep2 ;2/3
    ; sum:15 + X*(2+4*Y+2+4)+2
    ; 15 + X*(8+4*Y)+2
    ; 17 + X*(8+4*Y) 

    PLA     ;4
    TAX     ;2
    PLA     ;4
    TAY     ;2
    PLA     ;4
    NOP     ;1
    RTS     ;6
    ; 40 + X*(8+4*Y) --> 71, 93, 27020, 0.000740741




.segment "VECTS"
.org $FFFA
	.word	reset		; NMI 
	.word	reset		; RESET 
	.word	reset		; IRQ 