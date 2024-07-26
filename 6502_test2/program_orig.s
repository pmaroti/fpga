.org $A000

    CLD                 ; binary arithmetic
    SEI                 ; IRQ disable
    LDX #$7F            ; stack pointer to 128
    TXS

    LDA #$00
blink_loop:
uart_busy:
    LDX $CC21           ; check serial TX is busy???
    BNE uart_busy

    STA $CC20           ; Send to serial
    STA $CC10

    PHA                 ; Save accumulator
    LDX #82
delay_1000_loop:
    TXA
    JSR delay_12ms
    TAX
    DEX
    JMP delay_1000_loop
    PLA                 ; Restore accumulator

    ADC #1              ; increment A
    JMP blink_loop

delay_12ms:
    LDX #$00    ;#2
lp2:
    LDY #$00    ;#2
lp1:
    DEY         ;#2
    BNE lp1     ;#2,3   2+256*(2+3)+2=1284

    DEX         ;#2
    BNE lp2     ;#2,3  2+256*(2+1284+3)+2=329988
    RTS         ;#6 2+256*(2+1284+3)+2+6=
