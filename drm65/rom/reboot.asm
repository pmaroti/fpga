		*=$300-8

		.byte	$B0,$CA			; Marca
		.word	$300			; dirección de carga
		.word	$300			; dirección de ejecución
		.word	$2000+fin-ini	; Nº de bytes

ini:	sei
		lda		#3
		sta		1
		lda		#fin-ini
		sta		0
		lda		#$E0
		sta		3
		lda		#0
		sta		2

		ldy		#16			; Nos saltamos los registros E/S
cp1:	lda		(0),y
		sta		(2),y
		iny
		bne		cp1
		inc		1
		inc		3
		bne		cp1

		jmp		$FF00
fin:


