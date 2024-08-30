; ------------------------------------------------------------------------
; Define the I/O registres
	UTXD	=	$E000
	URXD	=	$E000
	USTAT	=	$E001
	BORDER	=	$E001
	CTRL1	=	$E002
	STAT1	=	$E002
	CTRL2	=	$E003
	STAT2	=	$E003
	PINOUT	=	$E004
	PININ	=	$E005
	PAL0	=	$E005
	PAL1	=	$E006
	PWM	=	$E007
	KBD	=	$E007
	PAGE0	=	$E008
	PAGE1	=	$E009
	PAGE2	=	$E00A
	PAGE3	=	$E00B
	PAGE4	=	$E00C
	PAGE5	=	$E00D
	PAGE6	=	$E00E

; ------------------------------------------------------------------------
; Define the ZP variables 

.zeropage

zpstart	= *
tmp1:	      	.res	1	; $00  Estas variables se salvan en pila
tmp2:	      	.res	1	; $01  si se entra en el monitor
tmp3:	      	.res	1	; $02  |
tmp4:	      	.res	1	; $03  |
ptr1:	      	.res	2	; $04  |
ptr2:	      	.res	2	; $06  |
ptr3:	      	.res	2	; $08  |
; Variables de propósito general usadas en rutinas de video
tmp5:	      	.res	1	; $0A
ptr4:	      	.res	2	; $0B
ptr5:	      	.res	2	; $0D
; Variables del sistema
tposx:		.res	1	; $0F  text position X (in chars)
tposy:		.res	1	; $10  text position Y (in chars)
cinflg:		.res	1	; $11  UART RX flags (via IRQ)
urxd:		.res	1	; $12  UART RX data (via IRQ)
brkp:		.res	3	; $13  Breakpoint address and op-code copy
spare:		.res	1	; $16 
coltxt:		.res	1	; $17  Text columns -1 (for monochrome mode)
iochan:		.res	1	; $18  canales de E/S (4 bit out, 4 bit in)
scankey:	.res	1	; $19  Scancode teclado
oscank:		.res	1	; $1A  Scancode anterior
modkey:		.res	1	; $1B  Modificadores del teclado (Mayusculas, ctrl,...)
keyrx:		.res	1	; $1C  Caracter tecleado

	.exportzp tposx, tposy, cinflg, urxd, brkp, endzp
endzp:


; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

.segment	"INIT"

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

.code

	.res	16	; Espacio para I/O
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;			VIDEO routines
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
	
	.include "video.s"

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
; 			IRQ/BRK Handler and debugger
;   (The first 40 instrucctions of this code must not cross a page)
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
	.include "irqbrk.s"


; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 				main program
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

fakerts:
	brk			; $E$x 
	brk
	rts
	
; ------------------------------------------------------------------------
; 				UART TX
; ------------------------------------------------------------------------
; uart_putchar
; parameters: A = data to print
; no register modified

	.export	uart_putchar, cout

uart_putchar:
upuch1:	bit	USTAT
	bpl	upuch1
	sta	UTXD
	rts

cout:	pha
	txa
	pha
	tya
	pha
	tsx
	inx
	inx
	inx

	lda	#$80		; set unread flag (for debug)
	ora	cinflg
	sta	cinflg

	lda	$100,x		; recupera A desde la pila
	bit	iochan
	bpl	cout2
	jsr	uart_putchar
cout2:	bit	iochan
	bvc	cout3
	jsr	gputch
cout3:	pla
	tay
	pla
	tax
	pla
	rts

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
; 			START
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
; Paleta por defecto:
palet:	.byte	$00, $03, $0C, $10, $C0, $20, $CC, $30
	.byte   $00, $4C, $0C, $5C, $C0, $6C, $CC, $7C
	.byte	$33, $83, $3F, $93, $F3, $A3, $FF, $B3
	.byte 	$33, $CF, $3F, $DF, $F3, $EF, $FF, $FF

	.export	_start
_start:
str0:	sei
	cld
	ldx	#4		; valores iniciales para páginas de RAM
				; bloques $4-$A (0-3: video, $B-$F: sin uso)
str05:	txa
	sta	PAGE0-4,x
	inx
	cpx	#11
	bne	str05

	ldx	#$ff		; Stack at the end of its page
	txs

	; init soft IRQ vectors
	lda	#<defISR
	sta	urxvec
	sta	utxvec
	sta	hsynvec
	sta	vsynvec
	lda	#>defISR
	sta	urxvec+1
	sta	utxvec+1
	sta	hsynvec+1
	sta	vsynvec+1
	
	; clear breakpoint
	lda	#0
	sta	brkp
	sta	brkp+1
	sta	cinflg		; Flags cin borrados
	sta	modkey		; modificadores en 0
	lda	#2	
	sta	CTRL2		; Video: 1bpp, IRQ teclado

	lda	#$C3		; Salida por UART y video, entrada UART y teclado
	sta	iochan
	lda	#63		; 64/85 columnas (fuente 8x16 o 6x16 pixels)
	sta	coltxt

	lda	#128		; PWM level 
	sta	PWM

	lda	#$E1		; Enable IRQ UART RX, clear flags
	sta	CTRL1
	cli			; Enable IRQs 
	
;--------------------------------------------
;	Code for tests
;--------------------------------------------

;---------------------------------------------	
;---------------------------------------------	
;	Load code and run it
;---------------------------------------------	
;---------------------------------------------	
	imgix = $30
	imgcnt= $31
	selin=	$32
	seloin=	$33
	botvec= $34


str1:	
	;set palette
	ldy	#0
str06:	lda	palet,y
	sta	PAL0
	iny
	lda	palet,y
	sta	PAL1
	iny
	cpy	#32
	bne	str06
	
	; set border
	lda	#8
	sta	BORDER

	; mensaje de arranque
	jsr	cls
	lda	#0
	sta	tposx
	sta	tposy

	ldx	#(msgboot-msgs)
	jsr	cputs

	; Lee directorio desde Flash SPI
	lda	PINOUT	; copia de PINOUT
	and	#$3F
	ora	#$30	
	sta	PINOUT	; SSs altos, MOSI y SCK bajos
	eor	#$20
	sta	PINOUT	; Flash_SS bajo
	lda	#3	; comando read
	jsr	spibyte
	lda	#9	; dir=$090000
	jsr	spibyte
	lda	#0
	jsr	spibyte
	lda	#0
	jsr	spibyte
	ldy	#0
	sty	ptr1
	lda	#3
	sta	ptr1+1
	ldx	#4
ldir1:	jsr	spibyte
	sta	(ptr1),y
	iny
	bne	ldir1
	inc	ptr1+1
	dex
	bne	ldir1
	lda	PINOUT
	ora	#$20
	sta	PINOUT	; SS bajo
	; Listado de imágenes cargables
ldir20:	lda	#0
	sta	imgix
ldir22:	lda	#0
	sta	imgcnt
	sta	ptr1
	lda	#3
	sta	ptr1+1
ldir2:	ldy	#0
	lda	(ptr1),y
	cmp	#$ff	; Final del listado
	beq	ldir9
	ldx	#' '
	lda	imgcnt
	cmp	imgix
	bne	ldir3
	ldx	#'>'
ldir3:	txa
	jsr	cout
	ldy	#3
ldir4:	lda	(ptr1),y
	beq	ldir5
	jsr	cout
	iny
	bne	ldir4
ldir5:	inc	imgcnt
	lda	#10
	jsr	cout
	lda	#64
	clc
	adc	ptr1
	sta	ptr1
	bcc	ldir2
	inc	ptr1+1
	jmp	ldir2
ldir9:	; Selecciona qué hacer
	lda	selin
	sta	seloin
	jsr	cin
	sta	selin
	cmp	#$CA
	bne	sel1
	lda	seloin
	cmp	#$B0
	bne	sel1
	jmp	load0

sel1:	cmp	#'B'	; Flecha abajo
	beq	seld
	cmp	#$91
	beq	seld
	cmp	#'A'	; Flecha arriba
	beq	selu
	cmp	#$90
	beq	selu
	cmp	#$93
	beq	selent
	cmp	#'C'
	beq	selent
	cmp	#13
	beq	selent

	jmp	ldir9

selu:	dec	imgix	; Flecha arriba
	bpl	selud
seld:	inc	imgix	; Flecha abajo
	lda	imgix
	cmp	imgcnt
	bne	selud
	dec	imgix
selud:	lda	#2
	sta	tposy
	jmp	ldir22

selent:	lda	#<spibyte
	sta	botvec
	lda	#>spibyte
	sta	botvec+1
	lda	#0		;ptr1=imgix*64+$300
	sta	ptr1
	lda	imgix
	sta	ptr1+1
	clc
	ror	ptr1+1
	ror	ptr1
	ror	ptr1+1
	ror	ptr1
	lda	#3
	clc
	adc	ptr1+1
	sta	ptr1+1
	ldy	#0
	lda	PINOUT	; copia de PINOUT
	and	#(~$20)&$ff
	sta	PINOUT	; SS bajo
	lda	#3	; comando read
	jsr	spibyte
	lda	(ptr1),y	; dir MSB
	jsr	spibyte
	iny
	lda	(ptr1),y	; dir medio
	jsr	spibyte
	iny
	lda	(ptr1),y	; dir LSB
	jsr	spibyte	

	jsr	spibyte		; Descartamos marca $B0, $CA
	jsr	spibyte	

	jmp	load1

	; A partir de ahora sin interrupciones pues puede llegar un crtl-C
load0:	lda	#<urawrx
	sta	botvec
	lda	#>urawrx
	sta	botvec+1
	sei

load1:	
	jsr	botin	; Dirección de carga en ptr1
	sta	ptr1
	jsr	botin
	sta	ptr1+1
	ora	#0	; pag 0 => Es una imagen o audio
	bne	load15
	lda	ptr1	; Bit 7 de dirección en 1 => audio
	bpl	load111
	jmp	loadaudio
load111:
	jsr	vmap	; Mapeamos video en $2000
	lda	#$20
	sta	ptr1+1
	lda	#0
	sta	PAL0	; Fondo negro
	sta	PAL1
	lda	#2	; Modo Monocromo
	sta	CTRL2
	lda	ptr1	; Dir LSB !=0 => color
	beq	load15
	lda	#3
	sta	CTRL2
	lda	#0
	sta	ptr1
load15:	jsr	botin	; Dirección de ejecución en ptr2
	sta	ptr2
	jsr	botin
	sta	ptr2+1

	jsr	botin	; Nº de bytes en tmp3:tmp4
	sta	tmp3
	jsr	botin
	sta	tmp4

	ldy	#0	; Bucle de carga
load2:	jsr	botin
	sta	(ptr1),y
	iny
	bne	load3
	inc	ptr1+1
load3:	dec	tmp3
	lda	tmp3
	cmp	#$FF
	bne	load4
	dec	tmp4
load4:	ora	tmp4
	bne	load2

	lda	#$0F	; Si páginas de video desmapeamos
	and	PAGE1
	bne	load45
	jsr	vunmap

load45:	; Cargado: ejecutar
	lda	PINOUT	; Por si SPI desactivamos SS
	ora	#$20
	sta	PINOUT

	lda	ptr2	; dir_exe=0 => no ejecutar
	ora	ptr2+1
	bne	load5
	lda	#0
	sta	tposy
load46:	jsr	cin
	cmp	#10
	beq	load46
	jmp	str1
load5:	cli		; ya con interrupciones
	jsr	load9	; Ejecutamos el código cargado como una subrutina
	jmp	str1

load9:	jmp	(ptr2)

botin:	jmp	(botvec)


urawrx:	bit	USTAT	; Lectura de UART via polling
	bvc	urawrx
	lda	URXD
	rts	

loadaudio:
	jsr	botin	; Nº de bytes complementado LSB
	eor	#$FF
	sta	tmp2
	jsr	botin
	eor	#$FF
	sta	tmp3
	jsr	botin
	eor	#$FF	; MSB
	sta	tmp4

laab0:	jsr	spibyte	; sample
	tax
	lda	#$20	; Espera por flanco de bajada en HSYN
laab1:	bit	CTRL1	; Espera HSYN en alto
	beq	laab1
laab2:	bit	CTRL1	; Espera HSYN en bajo
	bne	laab2
	stx	$E007	; nivel PWM
	inc	tmp2
	bne	laab0
	inc	tmp3
	bne	laab0
	inc	tmp4
	bne	laab0
	
	jmp	str1
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; SPI 8-bit transfer via bitbanging

spibyte:
	sta	tmp1
	txa
	pha
	ldx	#8
sb1:	lda	PINOUT
	asl
	asl	tmp1
	ror
sb2:	sta	PINOUT
	ora	#$40	; pulso SCK
	sta	PINOUT
	and	#$BF
	bit	PININ
	bpl	sb3
	inc	tmp1
sb3:	sta	PINOUT
	dex
	bne	sb1
	pla
	tax
	lda	tmp1
	rts

; ------------------------------------------------------------------------
; UART Get the input character in A

	.export	uart_getch, cin

uart_getch:
	cli			; enable IRQs (needed to get UART data)
	lda	#1		; wait until flag RX on
uget1:	bit	cinflg
	beq	uget1
uget2:	eor	cinflg		; clear flag
	sta	cinflg
	lda	urxd		; return data
	rts


; ------------------------------------------------------------------------	
; Console input: Espera por caracter, redibujando cursor si salida video
; Se usa el área "sch" para variables temporales
cin:	jsr	cinnb
	bcc	cin
	rts

;--------- versión no bloqueante (para basic)
cinnb:
	stx	sch+4
	sty	sch+3
	cli

cinb0:	lda	#1		; Check UART
	bit	iochan
	beq	cinb2
	bit	cinflg
	beq	cinb2
	eor	cinflg		; clear flag
	sta	cinflg
	lda	urxd
	bit	iochan
	bvc	cinb1
cinb05:	pha			; return data
	lda	#' '		; clear cursor
	jsr	gputch
	pla
	dec	tposx		; go back
cinb1:	ldx	sch+4		; restore X,Y
	ldy	sch+3
	sec			; notify data read (Carry on)
	rts

cinb2:	lda	#2		; Check Keyboard
	bit	iochan
	beq	cinb25
	bit	cinflg
	beq	cinb25
	eor	cinflg		; clear flag
	sta	cinflg
	lda	keyrx
	bit	iochan
	bvc	cinb1
	bvs	cinb05
	
cinb25:	bit	iochan		; Check if video for cout (for cursor draw)
	bvc	cinb9
	lda	STAT1		; Check for VSYN
	tax
	eor	#$ff
	and	sch+7
	and	#$10
	stx	sch+7
	beq	cinb9		; Vsync falling egde (60/sec)
	dec	sch+6		; every 15 Vsync (4/sec)...
	bne	cinb9
	lda	#15		; update count
	sta	sch+6
	lda	#' '		; redraw cursor
	cmp	sch+5
	bne	cinb3
	lda	#'_'
	bit	modkey		; If uppercase draw a different cursor (ASCII 127)
	bpl	cinb3
	lda	#127
cinb3:	sta	sch+5
	jsr	gputch		; print cursor
	dec	tposx		; go back

cinb9:	ldx	sch+4		; restore X,Y
	ldy	sch+3
	clc			; notify nothing to read (Carry off)
	rts
	

; ---------------------------------------------------------------------------	
; uputs: prints an ASCIIZ string via UART (used in debugger for ANSI escapes)
; arguments: X = offset from "msgs"
; returns: A, X, Y, tmp1, tmp2 modiffied

	.export	uputs
upt1:	jsr	uart_putchar
	inx
uputs:	lda	msgs,x
	bne	upt1
	rts	

; cputs: prints an ASCIIZ string via cout
	.export	cputs
cpt1:	jsr	cout
	inx
cputs:	lda	msgs,x
	bne	cpt1
	rts	


; ------------------------------------------------------------------------	
; cgets: gets a line with some editing
; arguments: ptr1 = pointer to destination data buffer
; output: A, X, Y modiffied

	.export	cgets
cgets:
	ldy 	#0
uags1:	jsr 	cin
	cmp 	#$D		; Ignore CR
	beq 	uags1
	cmp 	#$A		; End of Line
	bne 	uags2
	lda 	#0
	sta 	(ptr1),y
	rts
uags2:	cmp 	#$7F		; Backspace
	bne 	uags3
	cpy	#0
	beq 	uags1
	dey
	lda	#8		; one position back
	jsr	cout
	lda	#32		; erase old character by writing a space
	jsr	cout
	lda	#8		; one position back again
	jsr	cout
	jmp	uags1
uags3:	sta 	(ptr1),y
	jsr	cout	; echo
	iny
	jmp 	uags1

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
;       generic I/O routines (well, just output for now)
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; Print Acc as an hexadecimal number 

prthex:
	pha
	lsr	
	lsr	
	lsr	
	lsr	
	jsr	chexdig
	pla
	and	#$0f
chexdig:
	cmp	#10
	bcc	chex1	; Cy=1 => A >= 10
	adc	#('A'-('9'+1)-1)	; Cy was 1
chex1:	;clc	; not needed Cy is always 0
	adc	#'0'
	jmp	cout

; ------------------------------------------------------------------------
; number printing routines (32-bits)
; ------------------------------------------------------------------------
; tmp1-tmp4: data to be printed (return as zero)
; X,Y preserved. A modiffied
prtn32:	txa
	pha
	tya
	pha
	ldy	#0
prn1:	
	;------------- divide tmp1-tmp4 by 10. Remainder result in A
	ldx	#32
	lda	#0
dv1:	asl	tmp1
	rol	tmp2
	rol	tmp3
	rol	tmp4
	rol	a
	cmp	#10
	bcc	dv2
	sbc	#10
	inc	tmp1
dv2:	dex
	bne	dv1
	;-------------
	clc
	adc	#'0'
	pha
	iny
	lda	tmp1
	ora	tmp2
	ora	tmp3
	ora	tmp4
	bne	prn1
	;-------------
prn2:	pla
	jsr	cout
	dey
	bne	prn2
	pla
	tay
	pla
	tax
	rts

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
;	Dissasembler
	.include "dissa.s"

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
;	ASCII strings
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
	.export	msgs
msgs:
msgboot:	.byte   " - DRM65 by J. Arias -  Select Image:",10,10,0
msgcls:		.asciiz "                "
msgBRK:		.asciiz "   *** BRK ***"
msgPC:		.asciiz "PC="
msgP:		.asciiz "  P="
msgflags:	.asciiz "NVrBDIZC"
msgA:		.asciiz "  A="
msgX:		.asciiz "  X="
msgY:		.asciiz "  Y="
msgS:		.asciiz "  S="
msgspm:		.asciiz "- "
msgtab47:	.byte 27,"[48G",0
msgZP:		.byte "Zero Page Vars",0
msgstack:	.byte "Stack: ",0
msgmonprom:	.byte "hcsnrbmdgtpaxye >",0
msgclrrest:	.byte 27,"[J",0
msglcls:	.byte 27,"[2K",0
msghome:	.byte 27,"[H",27,"[K",0
msgtab28:	.byte 27,"[29G",0
msgback4:	.byte	8,8,8,8,0
msgpause:	.byte 10,"<MONpause>",0
msgNMI:		.asciiz "   *** NMI ***"

monhelp:	.byte 10,9,"h",9,"Help",10
		.byte 9,"c",9,"Continue",10
		.byte 9,"s",9,"Single step",10
		.byte 9,"n",9,"Next instr",10
		.byte 9,"r",9,"ends Routine",10
		.byte 9,"b <adr>",9,"Break at",10
		.byte 9,"m <adr>",9,"dump Mem",10
		.byte 9,"d <adr>",9,"Dissasemble",10
		.byte 9,"g <adr>",9,"Goto at",10
		.byte 9,"t <adr>",9,"Trace at",10
		.byte 9,"p nn",9,"edit P",10
		.byte 9,"a nn",9,"edit A",10
		.byte 9,"x nn",9,"edit X",10
		.byte 9,"y nn",9,"edit Y",10
		.byte 9,"e <adr>",9,"Edit mem",10
		.byte 9,"spc",9,"redraw",10
		.byte 9,"esc",9,"abort",0


;---------------------- Just to measure code lenght ----------------------
	.export endtxt
endtxt:

	.segment	"JUMPT"
; jump table with I/O routines
	jmp	str0		; $FF00 (-256)
	jmp	uart_putchar	; $FF03 (-253)
	jmp	uart_getch	; $FF06 (-250)
	jmp	cgets		; $FF09 (-247)
	jmp	prthex		; $FF0C (-244)

	jmp	cls		; $FF0F (-241)
	jmp	gputch		; $FF12 (-238)
	jmp	gputs		; $FF15 (-235)
	jmp	setpixel	; $FF18 (-232)
	jmp	clrpixel	; $FF1B (-229)
	jmp	tglpixel	; $FF1E (-226)
	jmp	putpixel4	; $FF21 (-223)

	jmp	cout		; $FF24 (-220)
	jmp	cin		; $FF27 (-217)
	jmp	cinnb		; $FF2A (-214)
	jmp	spibyte		; $FF2D	(-211)

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 	Variables in RAM (not in Zero Page)
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
	.segment	"BSS"
	.export	urxvec, utxvec, hsynvec, vsynvec
sch:		.res	8	; $200 Espacio temporal para variables de "cin"
urxvec:		.res	2	; $208 Vector IRQ UART RX
utxvec:		.res	2	; $20A Vector IRQ UART TX
vsynvec:	.res	2	; $20C Vector IRQ VSYN
hsynvec:	.res	2	; $20E Vector IRQ HSYN
param:		.res	8	; $210 Espacio para parámetros


; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 				Vectors
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
	.segment	"VECTORS"
	.export	vectorhNMI, vectorhRES, vectorhIRQBRK
vectorhNMI:	
	.byte <_nmi	;NMI
	.byte >_nmi
vectorhRES:
	.byte <_start	;RESET 
	.byte >_start
vectorhIRQBRK:
	.byte <_irqbrk	;IRQ/BRK
	.byte >_irqbrk
