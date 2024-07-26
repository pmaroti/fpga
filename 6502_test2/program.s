.org $AA00
    LDA #$00
blink_loop:
    STA $7F10
    ADC #1              ; increment A
    JMP blink_loop
