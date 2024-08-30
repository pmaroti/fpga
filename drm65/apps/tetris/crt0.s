;
; Startup code for cc65
;
; This must be the *first* file on the linker command line
;

	.export		_start			;, _exit
	.import	   	initlib, donelib
	.import	   	zerobss, push0
	.import		_main

	.export __CONSTRUCTOR_COUNT__, __DESTRUCTOR_COUNT__
	.export __CONSTRUCTOR_TABLE__, __DESTRUCTOR_TABLE__
	.export	__INTERRUPTOR_COUNT__, __INTERRUPTOR_TABLE__
	.export	__RAM_SIZE__, __RAM_START__
	__CONSTRUCTOR_COUNT__	= 0
	__DESTRUCTOR_COUNT__ 	= 0
	__CONSTRUCTOR_TABLE__ 	= 0
	__DESTRUCTOR_TABLE__ 	= 0
	__INTERRUPTOR_COUNT__ 	= 0
	__INTERRUPTOR_TABLE__ 	= 0
	__RAM_SIZE__ = 0
	__RAM_START__ = 0
; ------------------------------------------------------------------------
; Define and export the ZP variables for the C64 runtime

	.exportzp	sp, sreg, regsave
  	.exportzp	ptr1, ptr2, ptr3, ptr4
  	.exportzp	tmp1, tmp2, tmp3, tmp4
  	.exportzp	regbank, zpspace

; These zero page entries overlap with the sweet-16 registers in
; the standard apple2 linker config. They must be changed if sweet-16
; is to be supported

.zeropage

zpstart	= *
sp:	      	.res   	2 	; Stack pointer
sreg:	      	.res	2	; Secondary register/high 16 bit for longs
regsave:      	.res	2	; slot to save/restore (E)AX into
ptr1:	      	.res	2
ptr2:	      	.res	2
ptr3:	      	.res	2
ptr4:	      	.res	2
tmp1:	      	.res	1
tmp2:	      	.res	1
tmp3:	      	.res	1
tmp4:	      	.res	1
regbank:      	.res	6	; 6 byte register bank

zpspace	= * - zpstart		; Zero page space allocated

.code

; ------------------------------------------------------------------------
; Actual code

;       jmp     _start

; main program

_start:

; Clear the BSS data

	jsr	zerobss

; Setup the stacks

	lda    	#<$4000
	sta	sp
	lda	#>$4000
       	sta	sp+1   		; Main argument stack ptr

; Call module constructors

	jsr	initlib

; Pass an empty command line

	jsr	push0  	 	; argc
	jsr	push0  	 	; argv

	ldy	#4     	 	; Argument size
       	jsr    	_main  	 	; call the users code

; Call module destructors. This is also the _exit entry.

_exit:	jsr	donelib

L2:	rts

; system calls

;	.export _cout,
	.export _cinnb,_cls
	.import incsp1
;_cout:
;	ldy     #$00
;	lda     (sp),y
;	jsr	$FF24
;	jmp     incsp1

_cinnb:	jsr	$FF2A
	bcs	cinnb2
	lda	#0
cinnb2:	ldx	#0
	rts

_cls:	jmp	$FF0F
.data

.bss


