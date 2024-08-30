
#
# Makefile for cc65 samples
#
# This Makefile requires GNU make
#

# Enter the target system here
SYS	= atmos
BDIR    = /home/jesari/Descargas/cc65-2.13.3

CRT0   	= crt0.o
CLIB	= /usr/local/lib/cc65/lib/$(SYS).lib
CC	= cc65 -I $(BDIR)/include 
CL	= cl65
AS	= ca65 
LD	= ld65

#CC65_LIB=$(BDIR)/lib
#CC65_INC=$(BDIR)/include

# --------------------------------------------------------------------------
# Generic rules

.c.o:
	@echo $<
	@$(CC) -Oirs -T -t $(SYS) -I../include/ $<
	@$(AS) $(basename $<).s

.s.o:
	@echo $<
	@$(AS) $(basename $<).s


# --------------------------------------------------------------------------
# Rules how to make each one of the binaries

all:   	toload tetris

tetris:	crt0.o tetris.o $(CLIB)
	$(LD) -C config.ld -vm -m tetris.map -Ln tetris.lbl -o $@ $^
	./toload tetris
	cp out.bin ../../tetris

crt0.o:	crt0.s 

toload:	toload.c
	gcc -O2 -w -o $@ $<

clean:
	rm -f *.o *.map *.lbl *.lst irq.s uno.s *~
