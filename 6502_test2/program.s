.org $AA00
    LDA #$00
blink_loop:
uart_wait:
    LDX $CC21
    BNE uart_wait
    STA $CC20
    STA $CC10
    ADC #1              ; increment A
    JMP blink_loop
