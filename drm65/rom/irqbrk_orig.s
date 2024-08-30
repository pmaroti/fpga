; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 			IRQ & NMI routines
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

	.export _irqbrk
_irqbrk:
rql1:	pha			; save registers
	txa
	pha
	tya
	pha	
	cld			; decimal mode off
	lda 	#$02		; VIA CA1 IRQ ?
	bit 	IFR
	beq	irq2
	
	;--------------------------------
	; CA1 IRQ: read bitbang UART byte
	; ~33 cycles from IRQ to  here

	ldx	#8		;2 cycles 
irurx1:	
	pha			;3 cycles, 26 cycles/loop 
	lda	IRA		;4 cycles
	and	#(1<<RXD)	;2 cycles
	sbc	#1		;2 cycles
	pla			;4 cycles
	ror	a		;2 cycles
	nop			;2 cycles
	nop			;2 cycles
	dex			;2 cycles
	bne	irurx1		;3 cycles
	
	sta	urxd		; save received data
	cmp	#3		; CTL-C ? -> enter monitor
	bne	irux3
	lda	#~(1<<TXD)	; set TXD high to avoid breaks
	and	DDRA
	sta	DDRA
	ldy	#192		; alert with a beep
	jsr	beep1
	tsx
	inx
	inx
	inx
	inx
	jmp	dotim0
irux3:	lda	#1		; set RX flag
	ora	urtf
	sta	urtf
	lda	#(1<<RXD)
irurx2:	bit	IRA		; wait for the stop bit (to avoid repeated IRQs)
	beq	irurx2	
	jmp	finirq
	;--------------------------------

irq2:	tsx
	inx
	inx
	inx
	inx
	lda	$100,x		; Check if BRK
	and	#$10
	bne	dobrk
	; Not BRK 
nbrk:	lda	#$20		; check for Timer2 IRQ
	bit	IFR
	bpl	irql2		; not from VIA
	bne	dotimer		; from timer2
	; setting up a stack frame for a RTI return from a software vector
irq3:	lda	#>finirq	; PCH
	pha
	lda	#<finirq	; PCL
	pha
	lda	#0		; Status reg
	pha
	jmp    	(viavector) 
irql2:	; Not BRK nor from VIA
	; setting up a stack frame for a RTI return from a software vector
	lda	#>finirq	; PCH
	pha
	lda	#<finirq	; PCL
	pha
	lda	#0		; Status reg
	pha
	jmp	(irqothervector)
	
sstep:	tsx
	inx
	inx
	inx
	inx
	lda	#~4
	and	$100,x		; Clear the IRQ mask bit on the stack
	sta	$100,x
	; new IRQ just after returning and fetching 1 op-code	
	lda	#$A0
	sta	IER		; enable TIMER2 IRQ
	lda	#20		; 21.5 cycles until irq
	sta	T2CL		; write latch
	lda	#0
	sta	T2CH		; Write counter, clear IRQ
	
finirq:	; 22 cycles until return
	pla			; restore registers
	tay
	pla
	tax
	pla
defISR:	rti

	; NMI: jump to software vector
_nmi:	jmp	(nmivector)

; ------------------------------------------------------------------------
; 			Timer IRQ code (single step)
; ------------------------------------------------------------------------

	stacktop=tmp2		; aliases for some ZP variables
	zptop=ptr3

dotimer:
	lda	T2CL		; clear IRQ
dotim0:	ldy	#0		; saving needed ZP variables
dotim1:	lda	0,y
	pha
	iny
	cpy	#zptop
	bne	dotim1
	
	inx
	inx
reprt:	stx	tmp3		; begining of stack frame
	stx	stacktop		; (copy)
	lda	$100,x		; ptr1 = PC
	sta	ptr1+1
	dex
	lda	$100,x
	sta	ptr1
	jmp	dobrk4
; ------------------------------------------------------------------------
; 				BRK code
; ------------------------------------------------------------------------
dobrk:	ldy	#0		; saving needed ZP variables
dobrk1:	lda	0,y
	pha
	iny
	cpy	#zptop
	bne	dobrk1
	
	inx
	inx
	stx	tmp3		; begining of stack frame
	stx	stacktop	; (copy)

	; Check for breakpoint
	
	dex
	sec
	lda	$100,x		; ptr1 = PC-2
	sbc	#2
	sta	ptr1
	inx
	lda	$100,x
	sbc	#0
	sta	ptr1+1
		
	cmp	brkp+1		; ptr1 == brkp?
	bne	dobrk3
	lda	ptr1
	cmp	brkp
	bne	dobrk3
	ldy	#0		; it was a programmed breakpoint
	lda	brkp+2		; restore the original opcode
	sta	(ptr1),y
	lda	ptr1+1		; and adjust the PC copy on the stack
	sta	$100,x
	dex
	lda	ptr1
	sta	$100,x
	inx
	jmp	dobrk33
	
	; This breackpoint wasn't programmed, leave PC as it is
dobrk3:	lda	$100,x		; ptr1 = PC
	sta	ptr1+1
	dex
	lda	$100,x
	sta	ptr1
	
	lda	ptr1		; check if PC points to the fake RTS
	cmp	#<(fakerts+2)
	bne	dobrk35
	lda	ptr1+1
	cmp	#>(fakerts+2)
	bne	dobrk35
dobrk33:
	bit	urtf		; pause if there is some text to read
	bpl	dobrk4
	ldx	#(msgpause-msgs)
	jsr	uputs
	jsr	uart_getch	; pause
	jmp	dobrk4		; don't alert in this case
dobrk35:
	ldy	#192		; alert of BRK with a beep
	jsr	beep1
	
	lda	#$01		; Clear LCD
	jsr	LCD_cmd
	ldx	#(msgBRK-msgs) 	; *** BRK *** message on LCD
	jsr	lputs
	
	ldx	#(msghome-msgs)	; Go to upper-left corner of screen
	jsr	uputs
	ldx	#(msgBRK-msgs)	; *** BRK *** message on UART
	jsr	uputs
	jsr	nlinecls
	jmp	dbrk1
	
; ------------------------------------------------------------------------
;	Print state: registers
; ------------------------------------------------------------------------

dobrk4:	ldx	#(msghome-msgs)	; Go to upper-left corner of screen
	jsr	uputs
	
	; Register dump
dbrk1:	ldx	#(msgPC-msgs)
	jsr	uputs
	lda	ptr1+1		; PCH
	jsr	prthex
	dec	tmp3
	lda	ptr1		; PCL
	jsr	prthex
	dec	tmp3
	ldx	#(msgP-msgs)
	jsr	uputs
	ldx	tmp3
	lda	$100,x		; P
	ldy	#0		; Print P register bit by bit
bpreg:	asl	a
	pha
	lda	#'.'
	bcc	bpreg1
	lda	msgflags,y	
bpreg1:	jsr	cout
	pla
	iny
	cpy	#8
	bne	bpreg

	ldx	#(msgA-msgs)
	jsr	uputs
	ldy	tmp3
	dey
	lda	$100,y		; A
	jsr	prthex	

	ldx	#(msgX-msgs)
	jsr	uputs
	dey
	lda	$100,y		; X
	jsr	prthex	

	ldx	#(msgY-msgs)
	jsr	uputs
	dey
	lda	$100,y		; Y
	jsr	prthex
	
	ldx	#(msgS-msgs)
	jsr	uputs
	lda	tmp3		; S value before BRK
	jsr	prthex
	
	jsr	nlinecls
	ldx	#(msgZP-msgs)
	jsr	uputs
; ------------------------------------------------------------------------
;	Print state:
;	dissassemble 16 instrs at PC and dump Zero Page of memory
; ------------------------------------------------------------------------
	sty	tmp3
	jsr	nlinecls	; End of line
	
	jsr	dissaOP
	lda	ptr1		; save next instrucction address
	sta	ptr2
	lda	ptr1+1
	sta	ptr2+1
	ldx	#(msgtab28-msgs)
	jsr	uputs
	lda	#0
	jsr	prthex
	ldx	#(msgspm-msgs)
	jsr	uputs

	ldy	tmp3
	tsx
	inx
	stx	tmp3	
pzp1:	dey			; print ZP varibles from the stack
	lda	$100,y
	jsr	prthex
	lda	#' '
	jsr	cout
	cpy	tmp3
	bne	pzp1

	ldy	#zptop		; the rest of first line from ZP
pzp2:	lda	0,y
	iny
	jsr	prthex
	lda	#' '
	jsr	cout
	cpy	#16
	bne	pzp2
	jsr	nlinecls	; End of line
	ldy	#16
	
pzp3:	sty	tmp3		; rest of lines
	jsr	dissaOP
	ldy	tmp3
	ldx	#(msgtab28-msgs)
	jsr	uputs
	tya
	jsr	prthex
	ldx	#(msgspm-msgs)
	jsr	uputs
	ldx	#16
pzp4:	lda	0,y
	jsr	prthex
	lda	#' '
	jsr	cout	
	iny
	beq	pzpf
	dex
	bne	pzp4
	jsr	nlinecls
	jmp	pzp3

pzpf:	jsr	nlinecls
	jsr	nlinecls
	ldx	#(msgstack-msgs)	; print stack trace
	jsr	uputs
	lda	stacktop
	tax
	ldy	#24
pst1:	inx
	beq	pst2
	lda	$100,x
	jsr	prthex
	lda	#' '
	jsr	cout
	dey
	bne	pst1
pst2:	jsr	nlinecls
	
; ------------------------------------------------------------------------
; read a command from uart and execute it
; ------------------------------------------------------------------------

mon1:	ldx	#(msgmonprom-msgs) ;prompt on UART
	jsr	uputs
	jsr	uart_getch	; get character
	jsr	cout	; echo
	cmp	#'s'		; -------- single step -------
	bne	mon2
	jsr	nline
	sec
	jmp	dobrk5
mon2:	cmp	#'m'		; -------- memory dump -------
	bne	mon3
	jsr	dodir		; read address into ptr1
	bcs	mon1
	jsr	hexdump		; do dump
	jmp	mon1
mon3:	cmp	#'g'		; -------- goto address (execute) -------
	bne	mon35
	jsr	dodir		; read address into ptr1
	bcs	mon1
mon31:	clc
	ldx	stacktop	; and place it on the stack
	lda	ptr1+1
	sta	$100,x
	dex
	lda	ptr1
	sta	$100,x
	jmp	dobrk5
mon35:	cmp	#'t'		; --------  trace address (execute sigle-step)
	bne	mon4
	jsr	setbrk		; read breakpoint & address
	bcc	mon31		; unconditional branch
	jmp	mon1
mon4:	cmp	#'d'		; -------- dissasemble code ------- 
	bne	mon5
	jsr	dodir		; read address into ptr1
	bcs	mon1
dissa:	ldx	#16		; number of instuctions to dissasemble
dis01:	txa
	pha
	jsr	dissaOP		; dissasemble one OP-code
	jsr	nlinecls
	pla
	tax
	dex
	bne	dis01
	jmp	mon1
mon5:	cmp	#'c'		; -------- continue -------
	bne	mon6
mon55:	jsr	nline
	clc
	jmp	dobrk5
mon6:	cmp	#'n'		; -------- execute until next -------
	bne	mon7
	ldy	#0
	lda	(ptr2),y	; save orig opcode
	sta	brkp+2
	lda	ptr2		; save address
	sta	brkp
	lda	ptr2+1
	sta	brkp+1
	lda	#0
	sta	(ptr2),y	; put a BRK at the next instr
	jsr	nline
	clc
	jmp	dobrk5
mon7:	cmp	#'b'		; -------- place a breackpoint -------	
	bne	mon8
	jsr	setbrk
	jmp	mon1
mon8:	cmp	#' '		; -------- redraw screen -------
	bne	mon9
mon85:	ldx	stacktop
	jmp	reprt
mon9:	ldx	stacktop	; get reg. position in stack
	dex			; and copy it into ptr1
	dex
	cmp	#'p'		; -------- edit P reg. -------
	bne	mon10
	stx	tmp4
	lda	#' '
	jsr	cout
	ldx	#(msgflags-msgs)
	jsr	uputs
	ldx	tmp4
mon95:	stx	ptr1		; change stack value
	lda	#1
	sta	ptr1+1
	lda	#' '
	jsr	cout
	jsr	hexinby		; edit byte
	jmp	mon85		; and redraw screen
mon10:	dex
	cmp	#'a'		; -------- edit A reg. -------
	beq	mon95
	dex
	cmp	#'x'		; -------- edit X reg. -------
	beq	mon95
	dex
	cmp	#'y'		; -------- edit Y reg. -------
	beq	mon95
	cmp	#'e'		; -------- edit memory -------
	bne	mon12
	jsr	dodir		; get address of memory
	bcs	monf
mon11:	lda	#' '
	jsr	cout
	jsr	hexinby		; edit byte
	bcs	mon111
	inc	ptr1		; increment memory pointer
	bne	mon11
	inc	ptr1+1
	jmp	mon11
mon111:	jmp	mon1
mon12:	cmp	#'r'		;-------- execute the rest of subroutine -------
	bne	mon13
	tsx			; move stack trace 2 bytes down
	txa
	tay
	iny
	dex
	dex
	txs
	inx
mon121:	lda	$100,y
	sta	$100,x
	inx
	iny
	cpy	stacktop
	bne	mon121
	lda	$100,y		; last stack data
	sta	$100,x
	inx
	lda	#<(fakerts-1)	; place the fake return address on top of stack
	sta	$100,x
	inx
	lda	#>(fakerts-1)
	sta	$100,x
	jmp	mon55		; and continue execution
mon13:	cmp	#'h'
	bne	monf
	ldy	#0
mon131:	lda	monhelp,y
	beq	mon132
	jsr	cout
	iny
	bne	mon131
mon132:	
monf:	jmp	mon1

	; restore variables 
dobrk5:	lda	#$7f		; clear unread flag
	and	urtf
	sta	urtf
	ldy	#zptop
dobrk2:	pla
	dey
	sta	0,y
	bne	dobrk2
	bcc	dobrk6
	jmp	sstep		; finish IRQ/BRK with single-step
dobrk6:	jmp	finirq		; finish IRQ/BRK

; ------------------------------------------------------------------------
; debugger-related routines
; ------------------------------------------------------------------------
setbrk:	jsr	dodir		; read address into ptr1
	bcs	sbrk2
	lda	ptr1
	sta	brkp
	lda	ptr1+1
	sta	brkp+1
	ldy	#0
	lda	(ptr1),y
	sta	brkp+2
	tya
	sta	(ptr1),y	; brk op-code
	clc
sbrk2:	rts
		
; ------------------------------------------------------------------------
; print utilities
; ------------------------------------------------------------------------
nline:	lda	#10
	jmp	cout
nlinecls:
	ldx	#(msgnlcls-msgs)
	jmp	uputs
	

; ------------------------------------------------------------------------
; reads an address into ptr1. CY=1 -> read abort (ptr1 modiffied anyway)
; ------------------------------------------------------------------------

dodir:	jsr	uart_getch	; read char.
	cmp	#10		; EOL -> return
	bne	dodir3
dodir5:	lda	#10
	jsr	cout
	clc
	rts
dodir3:	cmp	#' '		; space -> input hex. number
	bne	dodir
	jsr	cout	
	jsr	hexin
	bcc	dodir5
	rts

; ------------------------------------------------------------------------
; dump a page of hexadecimal data
; returns: ptr1 pointing to the following page, 
;	   A, X, Y, tmp[1,2,3,4] modiffied
; ------------------------------------------------------------------------

hexdump:
	lda	#16			; 16 lines of 16 bytes
	sta	tmp3

hdump0:	lda	ptr1+1			; print hex. address
	jsr	prthex
	lda	ptr1
	jsr	prthex
	ldx	#(msgcls+14-msgs)	; print 2 spaces 
	jsr	uputs
	
	ldx	#16
	ldy	#0
hdump1:	lda	(ptr1),y		; print hex. data
	jsr	prthex	
	lda	#' '			; print space
	jsr	cout
	iny
	dex
	bne	hdump1
	
	lda	#' '			; print space
	jsr	cout
	
	ldx	#16			; print ASCII data
	ldy	#0
hdump2:	lda	(ptr1),y
	bpl	hdump3			; don't print ASCII > 127
	lda	#'.'
	bpl	hdump4
hdump3: cmp	#32			; don't print ASCII < 32
	bpl	hdump4
	lda	#'.'
hdump4:	jsr	cout
	iny
	dex
	bne	hdump2
	
	lda	#10			; new line
	jsr	cout

	clc				; PTR += 16
	lda	#16
	adc	ptr1
	sta	ptr1
	bcc	hdump5
	inc	ptr1+1

hdump5:	dec	tmp3
	bne	hdump0
	rts

; ------------------------------------------------------------------------
; inputs a 16-bit address into ptr1, CY=1 -> abort
; ------------------------------------------------------------------------

hexin:	lda	ptr1+1		; print current value
	jsr	prthex
	lda	ptr1
	jsr	prthex
	
hexin1:	jsr	uart_getch	; get chararecter
	cmp	#10		; EOL -> exit
	bne	hexin6
	clc
	rts
hexin6:	cmp	#27		; ESC -> abort
	bne	hexin5
	sec
	rts
hexin5:	jsr	ascii2hex
	bcs	hexin1
	ldx	#4
hexin4:	asl	ptr1		; shift value 4 bits and include new digit
	rol	ptr1+1
	dex
	bne	hexin4
	ora	ptr1
	sta	ptr1
	
	ldx	#(msgback4-msgs) ;go back 4 positions in the line
	jsr	uputs
	jmp	hexin

; ------------------------------------------------------------------------
; inputs a 8-bit address into (ptr1), CY=1 -> abort, tmp3 modiffied
; ------------------------------------------------------------------------
hexinby:
	ldy	#0
	lda	(ptr1),y
	sta	tmp3

hxb6:	jsr	prthex		; print current value

hxb1:	jsr	uart_getch	; get character
	cmp	#10		; NL: end edit
	bne	hxb2
hxb3:	lda	tmp3
	ldy	#0
	sta	(ptr1),y
	clc
	rts
hxb2:	cmp	#' '		; space: end edit
	beq	hxb3
	cmp	#27		; ESC : abort edit
	bne	hxb4
	sec
	rts
hxb4:	jsr	ascii2hex
	bcs	hxb1
	ldx	#4
hxb5:	asl	tmp3		; shift value 4 bits and include new digit
	dex
	bne	hxb5
	ora	tmp3
	sta	tmp3
	ldx	#(msgback4+2-msgs) ;go back 2 positions in the line
	jsr	uputs
	lda	tmp3
	jmp	hxb6

; ----------------------------------------------
; converts an ASCII Hex. char into a 4-bit value
; returns CY = 1 if not valid hex. digit
; ----------------------------------------------

ascii2hex:
a2x1:	cmp	#'0'		; ASCII < '0' -> ignore char.
	bmi	a2xf
	ora	#32		; to lowercase
	cmp	#'a'
	sec
	bpl	a2x2
	sbc	#'0'		; numbers (0 to 9)
	cmp	#10
	bpl	a2xf
	jmp	a2x3
a2x2:	sbc	#('a'-10)	; letters (a to f)
	cmp	#16
	bpl	a2xf
a2x3:	clc			; hex
	rts		
a2xf:	sec			; not hex
	rts

