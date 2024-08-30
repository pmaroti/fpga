CC      = gcc
CFLAGS  = -O2 -w -DLSB_FIRST -DDEBUG 

BDIR    = /home/jesus/cc65
AS65    = ca65 -l
LD65    = ld65
CC65    = cc65 -I $(BDIR)/include

OBJS    = main.o M6502.o Debug.o VIA.o

dep:	
	$(CC) -MM -I/usr/include *.c >.dep
	make all

all:	basic.bin

Dasm:	Dasm.c
	${CC} -o Dasm Dasm.c


basic.bin:	basic.asm Makefile config.ld
	$(AS65) $<
	$(LD65) -C config.ld basic.o
	cp basic.bin ../b

clean:	
	rm -f *.o *.lst *.map a.out *~

include	.dep
