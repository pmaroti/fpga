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

	;--------------------------------
	;	Check if BRK
	tsx
	inx
	inx
	inx
	inx		; 100,X -> saved P reg in stack
	lda	$100,x
	and	#$10
	beq	irq05
	jmp	dobrk
	;--------------------------------
	;  Hardware interrupts
irq05:	bit	STAT1		; HSYN?
	bmi	irhsyn
	bvs	irvsyn		; VSYN?
	bit	STAT2		; KBD
	bpl	irq1
	jmp	keyboardirq
irq1:	lda	#$10
	bit 	USTAT		; UART RX?
	beq	irq2
	lda	URXD
	sta	urxd		; save received data
	cmp	#('C'-64)	; CTL-C ? -> enter monitor
	bne	irux3
	jmp	dotim0
irux3:	lda	#1		; notify new data
	ora	cinflg
	sta	cinflg
	jmp	finirq
	;--------------------------------
irq2:	lda	#$20
	bit	USTAT
	bne	irutx		; UART TX?
	;------------------------------------------
irq25:	; Nothing else => was the single-step timer
	jmp	dotimer
	
sstep:	tsx
	inx
	inx
	inx
	inx
	lda	#(~4)&$ff
	and	$100,x		; Clear the IRQ mask bit on the stack
	sta	$100,x
	; new IRQ just after returning and fetching 1 op-code	
	lda	STAT1
	and	#$0F
	ora	#$10
	sta	CTRL1		; IRQ after 23 cycles	
	
finirq:	; 22 cycles until return
	pla			; restore registers
	tay
	pla
	tax
	pla
defISR:	rti

irhsyn:	; setting up a stack frame for a RTI return from a software vector
	lda	#>finirq	; PCH
	pha
	lda	#<finirq	; PCL
	pha
	lda	#0		; Status reg
	pha
	jmp    	(hsynvec) 

irvsyn:	; setting up a stack frame for a RTI return from a software vector
	lda	#>finirq	; PCH
	pha
	lda	#<finirq	; PCL
	pha
	lda	#0		; Status reg
	pha
	jmp    	(vsynvec) 

irutx:	; setting up a stack frame for a RTI return from a software vector
	lda	#>finirq	; PCH
	pha
	lda	#<finirq	; PCL
	pha
	lda	#0		; Status reg
	pha
	jmp    	(utxvec)

; ------------------------------------------------------------------------
	stacktop=tmp2		; aliases for some ZP variables
	zptop=tposx

; ------------------------------------------------------------------------
; NMI: Breakpoints hardware, (if there are any)
; ------------------------------------------------------------------------

_nmi:	pha			; save registers
	txa
	pha
	tya
	pha	
	cld			; decimal mode off
	tsx
	inx
	inx
	inx
	inx			; 100,X -> saved P reg in stack
	ldy	#0		; saving needed ZP variables
nmi1:	lda	0,y
	pha
	iny
	cpy	#zptop
	bne	nmi1
	
	inx
	inx
	stx	tmp3		; begining of stack frame
	stx	stacktop	; (copy)
	lda	$100,x		; ptr1 = PC
	sta	ptr1+1
	dex
	lda	$100,x
	sta	ptr1
	jsr	gohome
	ldx	#(msgNMI-msgs)	; *** NMI *** message on UART
	jmp	dbrk36

; ------------------------------------------------------------------------
; 			Timer IRQ code (single step)
; ------------------------------------------------------------------------

dotimer:
	lda	STAT1
	and	#$0F
	ora	#$20
	sta	CTRL1		; clear flag
dotim0:	ldy	#0		; saving needed ZP variables
dotim1:	lda	0,y
	pha
	iny
	cpy	#zptop
	bne	dotim1
	cli			; Permitimos anidar IRQs para no perder datos en cin

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
	cli			; Permitimos anidar IRQs para no perder datos en cin
	
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
	bit	cinflg		; pause if there is some text to read
	bpl	dobrk4
	ldx	#(msgpause-msgs)
	jsr	cputs
	jsr	cin	;uart_getch	; pause
	jmp	dobrk4		; don't alert in this case
dobrk35:
	jsr	gohome
	ldx	#(msgBRK-msgs)	; *** BRK *** message on UART
dbrk36:	jsr	cputs
	jsr	nlinecls
	jmp	dbrk1
	
; ------------------------------------------------------------------------
;	Print state: registers
; ------------------------------------------------------------------------

dobrk4:	lda     iochan          ; copia de estado de consola
        sta     sch
        lda     coltxt
        sta     sch+1
        lda     STAT2
        sta     sch+2
        and     #$FE            ; monocromo
        sta     CTRL2
        lda     #84
        sta     coltxt
        lda     #$C3
        sta     iochan

        jsr	gohome		; Go to upper-left corner of screen
	
	; Register dump
dbrk1:	ldx	#(msgPC-msgs)
	jsr	cputs
	lda	ptr1+1		; PCH
	jsr	prthex
	dec	tmp3
	lda	ptr1		; PCL
	jsr	prthex
	dec	tmp3
	ldx	#(msgP-msgs)
	jsr	cputs
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
	jsr	cputs
	ldy	tmp3
	dey
	lda	$100,y		; A
	jsr	prthex	

	ldx	#(msgX-msgs)
	jsr	cputs
	dey
	lda	$100,y		; X
	jsr	prthex	

	ldx	#(msgY-msgs)
	jsr	cputs
	dey
	lda	$100,y		; Y
	jsr	prthex
	
	ldx	#(msgS-msgs)
	jsr	cputs
	lda	tmp3		; S value before BRK
	jsr	prthex
	
	jsr	nlinecls
	
	bit	iochan
	bpl	bpr22
	ldx	#(msgtab47-msgs)
	jsr	uputs
bpr22:	bit	iochan
	bvc	bpr23
	lda	#47
	sta	tposx
bpr23:	ldx	#(msgZP-msgs)
	jsr	cputs
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
	jsr	tab28
	lda	#0
	jsr	prthex
	ldx	#(msgspm-msgs)
	jsr	cputs

	ldy	tmp3
	tsx
	inx
	stx	tmp3	
pzp1:	dey			; print ZP variables from the stack
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
	jsr	tab28
	tya
	jsr	prthex
	ldx	#(msgspm-msgs)
	jsr	cputs
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
	jsr	cputs
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

mon1:	jsr	nline
	bit	iochan
	bvc	mon01
	jsr	clrrest
mon01:	ldx	#(msgmonprom-msgs) ;prompt on UART
	jsr	cputs
	bit	iochan
	bpl	mon02
	ldx	#(msgclrrest-msgs) ;prompt on UART
	jsr	uputs

mon02:	jsr	cin	;uart_getch	; get character
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
dobrk5:	lda     sch             ; restaura estado de consola
        sta     iochan
        lda     sch+1
        sta     coltxt
        lda     sch+2
        sta     CTRL2

        lda	#$7f		; clear unread flag
	and	cinflg
	sta	cinflg
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
	lda	#10
	jsr	cout
	bit	iochan
	bpl	nlcls2
	ldx	#(msglcls-msgs)
	jsr	uputs
nlcls2:	bit	iochan
	bvc	sbrk2	
	jmp	clrline

gohome:	bit	iochan
	bpl	ghm1
	ldx	#(msghome-msgs)	; Go to upper-left corner of screen
	jsr	uputs
ghm1:	bit	iochan
	bvc	sbrk2
	lda	#0
	sta	tposx
	sta	tposy
	jmp	clrline

tab28:	bit	iochan
	bpl	tb282
	ldx	#(msgtab28-msgs)	; Go to upper-left corner of screen
	jsr	uputs
tb282:	bit	iochan
	bvc	sbrk2
	lda	#28
	sta	tposx
	rts
; ------------------------------------------------------------------------
; reads an address into ptr1. CY=1 -> read abort (ptr1 modiffied anyway)
; ------------------------------------------------------------------------

dodir:	jsr	cin		; read char.
	cmp	#13		; CR -> return
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
	jsr	cputs
	
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
	
hexin1:	jsr	cin		; get chararecter
	cmp	#13		; CR -> exit
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
	jsr	cputs
	jmp	hexin

; ------------------------------------------------------------------------
; inputs a 8-bit address into (ptr1), CY=1 -> abort, tmp3 modiffied
; ------------------------------------------------------------------------
hexinby:
	ldy	#0
	lda	(ptr1),y
	sta	tmp3

hxb6:	jsr	prthex		; print current value

hxb1:	jsr	cin		; get character
	cmp	#13		; CR: end edit
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
	jsr	cputs
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


;----------------------------------------------------
;     Keyboard IRQ
;----------------------------------------------------
keyboardirq:
	lda	KBD		; read scancode
	cmp	#$E0		; ignore prefix
	beq	ksigf0
	ldy	scankey
	sty	oscank
	sta	scankey
	cpy	#$F0		; released key?
	bne	kdown
	jmp	kup
kdown:	; Modiffiers?
	cmp	#$f0		; released, do not process
	beq	ksigf0
	cmp	#$12		; Shift left
	bne	ksig1
	lda	#$40
	ora	modkey
	sta	modkey
ksigf0:	jmp	finirq
ksig1:	cmp	#$59		; Shift right
	bne	ksig2
	lda	#$20
	ora	modkey
	sta	modkey
	jmp	finirq
ksig2:	cmp	#$58		; Uppercase
	bne	ksig3
	lda	#1
	bit	modkey
	bne	ksigf0
	ora	modkey
	eor	#$80
	sta	modkey
	jmp	finirq
ksig3:	cmp	#$14		; CTRL left / right
	bne	ksig4
	lda	#$10
	ora	modkey
	sta	modkey
	jmp	finirq
ksig4:	cmp	#$11		; ALT / ALT GR
	bne	ksig5
	lda	#$8
	ora	modkey
	sta	modkey
	jmp	finirq
ksig5:
	; Plain key: convert to ASCII
	tay
	lda	ktbl,y
	sta	keyrx

	lda	#$10	; CTRL modiffier?
	bit	modkey
	beq	noctrl
	lda	keyrx
	sec
	sbc	#96
	sta	keyrx
	cmp	#'V'-64	; CTRL-V as break to monitor
	bne	noalt	
	jmp	dotim0	; Break

noctrl:	lda	#$E0	; Uppercase modiffier?
	bit	modkey
	beq	nomay
	lda	keyrx	; Uppercase
	cmp	#'a'
	bcc	may2
	cmp	#'z'+1	; if 'a' < ascii <='z' simply subtract 32
	bcs	may2
	sec
	sbc	#32
	sta	keyrx
	jmp	noalt
may2:	; Other keys only are modiffied by 'shifts'
	lda	#$60	; shift left OR right?
	bit	modkey
	beq	nomay
	lda	keyrx
	cmp	#'0'	; keys 0 to 9 have a separate "number_shifted" table
	bcc	may3	;  "maytab1" 
	cmp	#'9'+1
	bcs	may3
	sec
	sbc	#'0'
	tay
	lda	maytab1,y
	sta	keyrx
may3:	; Other shifted keys (only if included in table "maytab2")
	ldy	#0
may31:	lda	maytab2,y	; key listed in table?
	beq	nomay
	cmp	keyrx
	beq	may32
	iny
	bne	may31
may32:	lda	maytab2b,y	; "mytab2b" have the values for these keys
	sta	keyrx

nomay:	lda	#$08	; ALT modiffier
	bit	modkey
	beq	noalt
	ldy	#0
alt11:	lda	alttab,y	; key listed in "alttab"?
	beq	noalt
	cmp	scankey
	beq	alt12
	iny
	bne	alt11
alt12:	lda	alttabb,y	; values for <ALT-key>
	sta	keyrx

noalt:
	lda	#2		; Notify new key
	ora	cinflg
	sta	cinflg

	jmp	finirq

	; Key released
kup:	cmp	#$12		; Shift left
	bne	ksigs1
	lda	#(~$40)&$ff
	and	modkey
	sta	modkey
	jmp	finirq
ksigs1: cmp	#$59		; Shift rigth
	bne	ksigs2
	lda	#(~$20)&$ff
	and	modkey
	sta	modkey
	jmp	finirq
ksigs2:	cmp	#$58		; Uppercase
	bne	ksigs3
	lda	#$FE
	and	modkey
	sta	modkey
	jmp	finirq
ksigs3:	cmp	#$14		; CTRL left / right
	bne	ksigs4
	lda	#(~$10)&$ff
	and	modkey
	sta	modkey
	jmp	finirq
ksigs4:	cmp	#$11		; ALT / ALT GR
	bne	ksigs5
	lda	#(~$8)&$ff
	and	modkey
	sta	modkey

ksigs5:
ksigf:	jmp	finirq

	; Main translation table. Scancode to Lowercase ASCII (132 entries)
ktbl:	.byte $00,$89,$00,$85,$83,$81,$82,$8C,$00,$8A,$88,$86,$84,$09,$5C,$00
	.byte $00,$00,$00,$00,$00,$71,$31,$00,$00,$00,$7A,$73,$61,$77,$32,$00
	.byte $00,$63,$78,$64,$65,$34,$33,$00,$00,$20,$76,$66,$74,$72,$35,$00
	.byte $00,$6E,$62,$68,$67,$79,$36,$00,$00,$00,$6D,$6A,$75,$37,$38,$00
	.byte $00,$2C,$6B,$69,$6F,$30,$39,$00,$00,$2E,$2D,$6C,$7E,$70,$27,$00
	.byte $00,$00,$7B,$00,$00,$00,$00,$00,$00,$00,$0D,$2B,$00,$7D,$00,$00
	.byte $00,$3C,$00,$00,$00,$00,$08,$00,$00,$97,$00,$92,$96,$00,$00,$00
	.byte $9A,$9B,$91,$00,$93,$90,$1B,$00,$8B,$00,$95,$00,$00,$94,$00,$00
	.byte $00,$00,$00,$87
maytab1:	.byte '=','!','"','#','$','%','&','/','(',')'	; shifted number values
maytab2:	.byte '<',$27,'+','-',',','.',0			; chars with special shift codes
maytab2b:	.byte '>','?','*','_',';',':',0			; values for shifted special chars
alttab:		.byte $16,$1E,$26,$54,$5B,0	; scancodes with ALT codes
alttabb:	.byte '|','@','#','[',']',0	; values for <ATL-key>

