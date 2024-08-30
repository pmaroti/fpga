; ------------------------------------------------------------------------
del5m:	; retardo de unos 5ms
	pha
	txa
	pha
	ldx 	#156
	lda	#$20
d5m1:	bit	STAT1	
	bne	d5m1
d5m2:	bit	STAT1	
	beq	d5m2
	dex
	bne	d5m1
	pla
	tax
	pla
	rts
; ------------------------------------------------------------------------
; Selection routines for MMC. 

	.export	mmc_cs_l, mmc_cs_h
mmc_cs_l:
	pha
	lda	#$EF	; /CS Low
	and	PINOUT	
mmccs1:	sta	PINOUT
	pla
	rts
mmc_cs_h:
	pha
	lda	#$10	; /CS High
	ora	PINOUT
	jmp	mmccs1

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 				MMC stuff
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; MMC_send_command: sends a 6-byte command to MMC/SD card
; arguments: MMCcmd structure
; returns: A: first byte of response (R1 according to standard)
; 	   X: modiffied

	.export	MMC_send_command
MMC_send_command:
	lda	#$ff		; dummy data
	jsr	spibyte
	ldx	#0
mmcsc1:	lda	MMCcmd,x	; command + addr + crc (6 bytes)
	jsr	spibyte
	inx
	cpx	#6
	bne	mmcsc1
	lda	#$ff
	jsr	spibyte		; dummy data
	ldx	#8
mmcsc2:	lda	#$ff		; wait for response up to 8 bytes
	jsr	spibyte
	bpl	mmcsc3
	dex
	bne	mmcsc2
mmcsc3:	rts

; ------------------------------------------------------------------------
; mmc_init: performs a SD card initialization acording to the SD standard
; (more or less)

	.export	mmc_init
mmc_init:
	jsr	mmc_cs_h	; /CS High
	
	ldx	#100		; some clock cycles for the card
mmcin1:	lda	#$ff
	jsr	spibyte
	dex
	bne	mmcin1
	
	jsr	mmc_cs_l	; /CS low
	
	lda	#$40		; GO_IDLE_STATE command
	sta	MMCcmd		; (with /CS low puts the card in SPI mode)
	lda	#0
	sta	MMCaddr0
	sta	MMCaddr1
	sta	MMCaddr2
	sta	MMCaddr3
	lda	#$95		; CRC has to be correct for this command
	sta	MMCcrc
	jsr	MMC_send_command
	jsr	mmc_cs_h	; /CS high
	cmp	#1		; correct response is 1: idle, no other error
	beq	mmcin2
mmcin0:	sec			; return with error
	rts
mmcin2:	jsr	spibyte		; 8 clock cycles
	jsr	mmc_cs_l
	lda	#$48		; SEND_IF_COND command (required for SD 2.0)
	sta	MMCcmd
	lda	#1
	sta	MMCaddr1
	lda	#$D5		; CRC has to be correct for this command
	sta	MMCcrc
	jsr	MMC_send_command
	sta	tmp1
	jsr	spibyte		; read 4 more response bytes
	jsr	spibyte
	jsr	spibyte
	sta	tmp2		; this byte contains the card's voltage 
	jsr	spibyte	
	jsr	mmc_cs_h
	lda	#4		; invalid command response if SD v 1.x
	bit	tmp1
	bne	mmcin6
	lda	#$0f
	and	tmp2
	cmp	#1		; voltage index = 1 (2.7 to 3.6 Volt)
	bne	mmcine
	
mmcin6:	lda	#0		; Now we send ACMD41 until an active response
	sta	MMCaddr1
	lda	#$ff
	sta	MMCcrc    
	ldy	#40		; number of retries
mmcin5:	lda	#$ff
	jsr	spibyte		; 8 clock cycles
	jsr	mmc_cs_l
	lda	#$77		; APP_CMD is required prior to ACMDs
	sta	MMCcmd
	jsr	MMC_send_command
	lda	#$ff
	jsr	spibyte
	lda	#$69		; ACMD41 command
	sta	MMCcmd
	lda	#$ff
	jsr	MMC_send_command
	and	#1		; retry if still in idle state
	beq	mmcin4
	ldx	#5
mmcin3:	jsr	del5m		; 25 ms delay between retries
	dex
	bne	mmcin3
	jsr	mmc_cs_h
	dey
	bne	mmcin5
mmcine:	sec			; return with error
	rts
mmcin4:	clc			; return OK
	rts

; ------------------------------------------------------------------------
; mmc_read_sector: 
; arguments: sector[0,1,2]: sector to be read
;	     ptr1: pointer to destination buffer
; returns CY=1 if error
; modiffies: A, X, Y, MMCcmd structure

	.export	mmc_rd_sector
mmc_rd_sector:
	lda	#0		; MMC address = sector * 512
	sta	MMCaddr0
	lda	sector0
	asl	a
	sta	MMCaddr1
	lda	sector1
	rol	a
	sta	MMCaddr2
	lda	sector2
	rol	a
	sta	MMCaddr3
	
	jsr	mmc_cs_l
	lda	#$51
	sta	MMCcmd		; READ_SINGLE_BLOCK command
	jsr	MMC_send_command
	ora	#0
	bne	mmcrd1
	
mmcrd2:	lda	#$ff		; wait for data tokem
	jsr	spibyte
	cmp	#$fe	
	bne	mmcrd2
	
	ldy	#0
	jsr	spird		; 256 bytes to low buffer
	inc	ptr1+1
	jsr	spird		; 256 bytes to high buffer
	dec	ptr1+1
	lda	#$ff		; ignore CRC16
	jsr	spibyte
	lda	#$ff
	jsr	spibyte
	jsr	mmc_cs_h
	clc
	rts	
	
mmcrd1:	jsr	mmc_cs_h	; error, set carry
	sec
	rts
	
; ------------------------------------------------------------------------
; mmc_write_sector: 
; arguments: sector[0,1,2]: sector to be written
;	     ptr1: pointer to source buffer
; returns CY=1 if error
; modiffies: A, X, Y, MMCcmd structure

	.export mmc_wr_sector
mmc_wr_sector:
	lda	#0		; MMC address = sector * 512
	sta	MMCaddr0
	lda	sector0
	asl	a
	sta	MMCaddr1
	lda	sector1
	rol	a
	sta	MMCaddr2
	lda	sector2
	rol	a
	sta	MMCaddr3
	
	jsr	mmc_cs_l
	lda	#$58
	sta	MMCcmd		; WRITE_SINGLE_BLOCK command
	jsr	MMC_send_command
	ora	#0
	bne	mmcwr1
	
	lda	#$FE
	jsr	spibyte		; send data tokem
	
	ldy	#0		; 256 bytes from low buffer
	jsr	spiwr
	inc	ptr1+1
	jsr	spiwr		; 256 bytes from high buffer
	dec	ptr1+1
	lda	#$ff		; send a dummy CRC-16
	jsr	spibyte
	lda	#$ff
	jsr	spibyte
	lda	#$ff
	jsr	spibyte		; response
mmcwr2:	lda	#$ff
	jsr	spibyte		; wait while busy (response==0)
	beq	mmcwr2
	jsr	mmc_cs_h
	clc
	rts

mmcwr1: jsr	mmc_cs_h
fatie:	sec
	rts
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; 			FAT-16 Filesystem
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; FAT_init: locates filesystem partition, read parameters and offsets
; returns CY=1 if something went wrong

	.export	FAT_init
FAT_init:
	lda	#0
	sta	sector0		; read partition table (sector 0)
	sta	sector1
	sta	sector2
	lda	#<fatbuf	; destination buffer
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	mmc_rd_sector
	bcs	fatie
	
fati0:	lda	fatbuf+$1c6	; save filesystem offset (only 24 bits)
	sta	sector0		; the MSB byte is always 0
	sta	FAT
	lda	fatbuf+$1c7
	sta	sector1
	sta	FAT+1
	lda	fatbuf+$1c8
	sta	sector2
	sta	FAT+2

fati00:	jsr	mmc_rd_sector	; read superblock
	bcs	fatie

	clc			; FAT = offset to FAT (in sectors)
	lda	fatbuf+14	; FAT = offset to partition + reserved sectors
	adc	FAT
	sta	FAT
	lda	fatbuf+15
	adc	FAT+1
	sta	FAT+1
	bcc	fati4
	inc	FAT+2
fati4:	lda	FAT
	sta	FATrootsec	; offset to root directory
	lda	FAT+1		; FATrootsec = offset to FAT + sectors/FAT*nFAT
	sta	FATrootsec+1
	lda	FAT+2
	sta	FATrootsec+2

	lda	fatbuf+22
	sta	tmp1		; tmp1,tmp2: sectors/FAT
	lda	fatbuf+23
	sta	tmp2
	lda	fatbuf+16
	sta	tmp3		; tmp3: nfat

	; multiply and accumulate
fati1:	lsr	tmp3		; nfat*sectors_per_fat
	bcc	fati2
	clc
	lda	tmp1
	adc	FATrootsec
	sta	FATrootsec
	lda	tmp2
	adc	FATrootsec+1
	sta	FATrootsec+1
	bcc	fati2
	inc	FATrootsec+2
fati2:	asl	tmp1
	rol	tmp2
	lda	tmp3
	bne	fati1
	
	lda	fatbuf+13
	sta	FATsecperclus	; Parameter: sectors / cluster

	lda	fatbuf+17	; number of root entries (32 bytes/entry)
	sta	FATnrootsec	; FATnrootsec: number of sectors of root
	lda	fatbuf+18	; FATnrootsec = number of root entries / 16
	lsr	a
	ror	FATnrootsec
	lsr	a
	ror	FATnrootsec
	lsr	a
	ror	FATnrootsec
	lsr	a
	ror	FATnrootsec
	sta	FATnrootsec+1

	lda	#0		; Init other variables
	sta	dircluster	; Current directory: root
	sta	dircluster+1	
	sta	FileFlags	; No EOF
	clc
	rts


; -------------------------------------------------------------------------------
; FAT_search_dir: search for a file in the current directory
; Arguments: ptr2: pointer to a 11-character filename (name spaces ext)
; returns CY=1 if not found, else cluster, sector, Filesize and sectorcnt are set
; modifies A, X, Y, tmp[1,2], ptr1, sector, cluster, sectorcnt, MMCcmd

	.export	FAT_search_dir
FAT_search_dir:
	jsr	setupdir

fsd1:	lda	#<fatbuf	; Read from file to FAT buffer
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	read_sector_from_file
	bcs	fsd9		; No more clusters -> return
	
	ldx	#16		; Dir entries per sector
	lda	#>fatbuf	; restore ptr1 ("read_sector_from_file" adds 512 to it)
	sta	ptr1+1

fatsd2:	ldy	#10		; 11-char filename
fatsd3:	lda	(ptr2),y	; filename comparison
	cmp	(ptr1),y
	bne	fatsd4
	dey
	bpl	fatsd3

fatsd10: 
	ldy	#26		; FOUND: save file data
pru1:	lda	(ptr1),y	; cluster & Filesize (total: 6 bytes)
	sta	cluster-26,y
	iny
	cpy	#(26+6)
	bne	pru1
	jsr	FAT_clus2sec	
	lda	FATsecperclus
	sta	sectorcnt
	lda	#0
	sta	FileFlags
	clc
	rts

fatsd4:	lda	#32		; next directoy entry
	clc
	adc	ptr1
	sta	ptr1
	bcc	fatsd5
	inc	ptr1+1
fatsd5:	dex
	bne	fatsd2
	beq	fsd1		; next sector of directory

fsd9:	sec			; NOT FOUND
	rts

; ------------------------------------------------------------------------
;  Chose the right directory to scan 
; ------------------------------------------------------------------------

setupdir:
	lda	dircluster	; Root dir or subdir?
	ora	dircluster+1
	bne	stdir1

	lda	FATrootsec	; Root dir: emulate file read
	sta	sector0		; first sector
	lda	FATrootsec+1
	sta	sector1
	lda	FATrootsec+2
	sta	sector2	
	lda	FATnrootsec	; # of sectors (<256)
	sta	sectorcnt
	lda	#0
	sta	cluster		; #cluster 0 (no following clusters)
	sta	cluster+1
	rts

stdir1:	lda	dircluster	; Start reading from subdir
	sta	cluster
	lda	dircluster+1
	sta	cluster+1
	jsr	FAT_clus2sec
	lda	FATsecperclus
	sta	sectorcnt
	rts

; -------------------------------------------------------------------------------
; FAT_list_dir: list current directory
; -------------------------------------------------------------------------------

	.export	FAT_list_dir
FAT_list_dir:
	jsr	setupdir

fld1:	lda	#<fatbuf	; Read from file to FAT buffer
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	read_sector_from_file
	bcs	fld9		; No more clusters -> return
	
	ldx	#16		; Dir entries per sector
	lda	#>fatbuf	; restore ptr1 ("read_sector_from_file" adds 512 to it)
	sta	ptr1+1

fld2:	ldy	#11
	lda	(ptr1),y
	sta	tmp1		; save a copy of attributes
	cmp	#$0f		; Long filename extension -> ignore
	beq	fld4		
	ldy	#0
	lda	(ptr1),y
	beq	fld9		; 0 -> directory end
	cmp	#$e5		; deleted entry -> ignore
	beq	fld4	
	lda	#$10
	and	tmp1		; subdir?
	beq	fld25		
	lda	#'/'
	bne	fld26
fld25:	lda	#' '
fld26:	jsr	cout

fld3:	lda	(ptr1),y	; filename printing
	jsr	cout
	iny
	cpy	#11		; up to 11 bytes
	bne	fld3
	lda	#9
	jsr	cout

	ldy	#28		; print Filelength
fld35:	lda	(ptr1),y
	sta	-28,y		; stored in tmp1 to tmp4 (ZP addresses 0 to 3)
	iny
	cpy	#32
	bne	fld35
	jsr	prtn32
	lda	#10
	jsr	cout

fld4:	lda	#32		; next directory entry
	clc
	adc	ptr1
	sta	ptr1
	bcc	fld5
	inc	ptr1+1
fld5:	dex
	bne	fld2
	beq	fld1		; next sector of directory

fld9:	sec			; NOT FOUND
	rts

; ------------------------------------------------------------------------
; cluster to sector
; ------------------------------------------------------------------------
; arguments: cluster,cluster+1
; result: sector0,1,2

	.export	FAT_clus2sec
FAT_clus2sec:
	lda	cluster		; tmp1:2:3 = cluster-2 
	sec
	sbc	#2
	sta	tmp1
	lda	cluster+1
	sbc	#0
	sta	tmp2
	lda	#0
	sta	tmp3
	
	clc
	lda	FATrootsec	; offset to root + number of root sectors
	adc	FATnrootsec
	sta	sector0
	lda	FATrootsec+1
	adc	FATnrootsec+1
	sta	sector1
	lda	FATrootsec+2
	adc	#0
	sta	sector2
	
	lda	FATsecperclus
	sta	tmp4
	; multiply and accumulate ( sector += sectors_per_cluster * (cluster-2) )
	bne	fatsd11		; always taken
fatsd13:
	clc
	lda	tmp1
	adc	sector0
	sta	sector0
	lda	tmp2
	adc	sector1
	sta	sector1
	lda	tmp3
	adc	sector2
	sta	sector2	
fatsd12:
	asl	tmp1
	rol	tmp2
	rol	tmp3
fatsd11:
	lsr	tmp4
	bcs	fatsd13
	bne	fatsd12
	
	rts	; returns: sector=(cluster-2)*FATsecperclus

; ------------------------------------------------------------------------
; Search the next cluster from FAT table
; ------------------------------------------------------------------------
; arguments: cluster,cluster+1
; result: cluster,cluster+1, CY=1 if no more clusters in the current chain
; modiffies A,X,Y, ptr1, sector

	.export FAT_next_cluster
FAT_next_cluster:
	lda	#<fatbuf	; temporary buffer
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1

	clc
	lda	FAT		; sector = FAT + cluster/256
	adc	cluster+1
	sta	sector0
	lda	FAT+1
	adc	#0
	sta	sector1
	lda	FAT+2
	adc	#0
	sta	sector2
	jsr	mmc_rd_sector
	
	lda	cluster
	asl	a		; 2 byte per cluster (FAT-16)
	tax
	bcs	fatnc1		
	lda	fatbuf,x	; First half of sector (256 bytes)
	sta	cluster
	lda	fatbuf+1,x
	sta	cluster+1
	bcc	fatnc2		; always taken
fatnc1:	lda	fatbuf+$100,x	; Second half of sector (256 bytes)
	sta	cluster
	lda	fatbuf+$101,x
	sta	cluster+1
fatnc2: 
	lda	#$0f		; if cluster=$FFFx returns CY=1
	ora	cluster
	cmp	#$ff
	bne	fatnc3
	lda	cluster+1
	cmp	#$ff
	bne	fatnc3
	sec		
	rts
fatnc3:	clc
bsdff:	rts

;-----------------------------------------------------------------
;	Sequential reading from file
;-----------------------------------------------------------------
;	returns CY active if no more clusters available
;	Sets FileFlags.7 if the size of the file is exceeded

read_sector_from_file:

	lda	sectorcnt	; No more sectors in the cluster?
	bne	rsff1
	lda	FATsecperclus
	sta	sectorcnt
	lda	ptr1+1		; save destination pointer
	pha
	lda	ptr1
	pha
	jsr	FAT_next_cluster
	pla			; restore pointer
	sta	ptr1
	pla
	sta	ptr1+1
	bcs	rts2		; error from FAT_next_cluster
	jsr	FAT_clus2sec

rsff1:	jsr	mmc_rd_sector	; read it
	bcs	rts2

	inc	ptr1+1		; ptr1 += 512
	inc	ptr1+1
	dec	sectorcnt
	inc	sector
	bne	rsff2
	inc	sector+1
	bne	rsff2
	inc	sector+2
rsff2:	sec			; Filesize-=512
	lda	Filesize+1
	sbc	#2
	sta	Filesize+1
	lda	Filesize+2
	sbc	#0
	sta	Filesize+2
	lda	Filesize+3
	sbc	#0
	sta	Filesize+3
	bmi	rsff3		; Filesize negative -> set EOF
	lda	Filesize
	ora	Filesize+1
	ora	Filesize+2
	ora	Filesize+3
	beq	rsff3		; Filesize = 0 -> end
	clc
	rts

rsff3:	lda	#$80
	sta	FileFlags
	clc
	rts

;-----------------------------------------------------------------
;	change to a directory
;-----------------------------------------------------------------
; ptr2: directory name (11 chars)
; returns CY active if not found

FAT_chdir:
	jsr	FAT_search_dir
	bcs	rts2
	lda	cluster
	sta	dircluster
	lda	cluster+1
	sta	dircluster+1
rts2:	rts

;-----------------------------------------------------------------
;		SD bootloader
;-----------------------------------------------------------------
execfile:
	jsr	FAT_search_dir
	bcs	rts2
	
	lda	#<fatbuf	; first, read a single sector to the buffer
	sta	ptr1
	lda	#>fatbuf
	sta	ptr1+1
	jsr	read_sector_from_file
	bcs	rts2

	lda	fatbuf		; check for mark: $B0,$CA
	cmp	#$B0
	bne	rts2
	lda	fatbuf+1
	cmp	#$CA
	bne	rts2

	ldx	#(msgldx-msgs)
	jsr	uputs
	
	sec			; loadaddr-=8 to skip header
	lda	fatbuf+2	; save load address and exec. address
	sbc	#8
	sta	ptr1
	lda	fatbuf+3
	sbc	#0
	sta	ptr1+1
	lda	fatbuf+4
	sta	ptr2
	lda	fatbuf+5
	sta	ptr2+1

	ldy	#8	; copy first sector (without header) to its destination address
bsd2:	lda	fatbuf,y
	sta	(ptr1),y
	iny
	bne	bsd2
	inc	ptr1+1
bsd3:	lda	fatbuf+256,y
	sta	(ptr1),y
	iny
	bne	bsd3
	inc	ptr1+1
				; read the rest of the file
bsd4:	jsr	read_sector_from_file
	bcs	bsdf
	bit	FileFlags	; repeat until EOF
	bpl	bsd4

bsdd:	lda	ptr2+1		; execute if exec address >= $300
	cmp	#3
	bcc	bsdf
	ldx	#(msgexe-msgs)	; notify execution on UART 
	jsr	uputs
	jmp	(ptr2)
	
bsdf:	rts


