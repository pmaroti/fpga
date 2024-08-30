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

	tmp1	= $00
	tmp2	= $01
	tmp3	= $02
	tmp4	= $03
	ptr1	= $04
	ptr2	= $06
	ptr3	= $08
	
	coltxt	= $17

.zeropage
	.exportzp	MMCcmd,sector,cluster,dircluster,FAT,FATsecperclus
	.exportzp	FATnrootsec,FATrootsec,Filesize

MMCcmd:		.res	1	; MMC command+address(32 bits)+crc
MMCaddr3:	.res	1
MMCaddr2:	.res	1
MMCaddr1:	.res	1
MMCaddr0:	.res	1
MMCcrc:		.res	1
sector:
sector0:	.res	1	; sector: 24 bits
sector1:	.res	1
sector2:	.res	1

FAT:		.res	3	; first sector of the FAT (1st copy)
FATsecperclus:	.res	1	
FATnrootsec:	.res	2	; number of sectors of the root directory
FATrootsec:	.res	3	; first sector of the root directory

dircluster:	.res	2	; start cluster for current subdirectory (zero if root)

cluster:	.res	2	; current cluster (16 bits)
Filesize:	.res	4	; cluster and Filesize must be on consecutive addresses
sectorcnt:	.res	1	; Remaining sectors in the cluster
FileFlags:	.res	1	; Flags for files (only EOF yet)


; ------------------------------------------------------------------------
; Define ROM functions
	cout =		$FF24
	cin =		$FF27
	spibyte =	$FF2D

;----------------------------------------------------
; Header
.code
	.byte	$B0, $CA
	.word	loadaddr
	.word	inicio
	.word	endcode-loadaddr
	
loadaddr:
;----------------------------------------------------
inicio:	;lda	#84
	;sta	coltxt
	jsr	mmc_init
	bcs	dcmd
	ldx	#(msgSD-msgs)	; notify on UART also
	jsr	uputs

	jsr	FAT_init
	bcs	dcmd
	ldx	#(msgFAT-msgs)	; notify on UART also
	jsr	uputs
	;------------------------ root directory listing
	lda	#10
	jsr	cout	
	jsr	FAT_list_dir
dcmd:	jmp	doscmd
;----------------------------------------------------

	.include "spi.s"
	.include "mmc.s"
;----------------------------------------------------
toupper:
	ldx	#0
tu1:	lda	fatbuf,x
	beq	turts
	cmp	#'a'
	bcc	tu2
	cmp	#'z'+1
	bcs	tu2
	and	#$DF
tu2:	;jsr	cout
	sta	fatbuf,x
	inx
	bne	tu1
turts:	rts
;----------------------------------------------------
padname:
	ldx	#0
	stx	tmp1

pn1:	inx
	lda	fatbuf,x
	beq	turts
	cmp	#' '
	beq	pn1
	ldy	#0
pn2:	lda	fatbuf,x
	beq	pn3
	cmp	#'.'
	bne	pn5
	bit	tmp1
	bpl	pn5
	inx
	lda	#' '
pn6:	cpy	#8
	bcs	pn2
	sta	filename,y
	;jsr	cout
	iny
	jmp	pn6
pn5:	cmp	#' '
	beq	pn3
	sta	filename,y
	;jsr	cout
	cmp	#'.'
	beq	pn55
	lda	#$80	
	sta	tmp1
pn55:	inx
	iny
	cpy	#11
	bne	pn2
pn3:	lda	#' '
pn4:	cpy	#11
	beq	turts
	sta	filename,y
	;jsr	cout
	iny
	jmp	pn4
;----------------------------------------------------	
doscmd:	
dcl0:	ldx	#(msgdprt-msgs)
	jsr	uputs
	lda	#<fatbuf
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	cgets
	jsr	toupper
	lda	#10
	jsr	cout

	jsr	padname
	lda	#<filename
	sta	ptr2
	lda	#>filename
	sta	ptr2+1

	lda	fatbuf
	cmp	#'D'
	bne	dcl1
	jsr	FAT_list_dir
	jmp	dcl0

dcl1:	cmp	#'C'
	bne	dcl2
	jsr	FAT_chdir
dcl6:	ldx	#(msgok-msgs)
	bcc	dcl4
dcl7:	ldx	#(msgerr-msgs)
dcl4:	jsr	uputs
	lda	#10
	jsr	cout
	jmp	dcl0

dcl2:	cmp	#'Q'
	bne	dcl3
	rts

dcl3:	cmp	#'R'
	bne	dcl5
	jsr	mmc_init
	bcs	dcl7
	jsr	FAT_init
	jmp	dcl6

dcl5:	cmp	#'T'
	bne	dcl11
	jsr	FAT_search_dir
	bcs	dcl7
dcl8:	lda	#<fatbuf
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	read_sector_from_file
	bcs	dcl7
	lda	#>fatbuf
	sta	ptr1+1
	ldy	#0
dcl9:	lda	fatbuf,y
	jsr	cout
	iny
	bne	dcl9
dcl10:	lda	fatbuf+256,y
	jsr	cout
	iny
	bne	dcl10
	bit	FileFlags
	bpl	dcl8
	jmp	dcl0

dcl11:	cmp	#'X'
	bne	dcl12
	jsr	execfile
	lda	#10
	jsr	cout

dcl12:	jmp	dcl0

; ------------------------------------------------------------------------
	.export	uputs
upt1:	jsr	cout
	inx
uputs:	lda	msgs,x
	bne	upt1
	rts	

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
; uart_gets: gets a line with some editing
; arguments: ptr1 = pointer to destination data buffer
; output: A, X, Y modiffied
	
cgets:
	ldy 	#0
uags1:	jsr 	cin
	cmp 	#$A		; Ignore CR
	beq 	uags1
	cmp 	#$D		; End of Line
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
	.export	msgs
msgs:
msgerr:		.asciiz "Error"
msgok:		.asciiz "OK"
msgSD:		.asciiz "SD ok "
msgFAT:		.asciiz "FAT ok "
msgldx:		.asciiz ".load"
msgexe:		.asciiz ".exe "
msgdprt:	.asciiz "rdctx>"

endcode:


; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 				DATA & BSS
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

.bss
	.export	fatbuf,filename
	fatbuf:		.res	512	; buffer for FAT operations
	filename:	.res 	11	; DOS file names






