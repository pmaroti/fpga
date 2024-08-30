CC      = gcc
CFLAGS  = -O2 -w -DLSB_FIRST -DDEBUG 

BDIR    = /home/jesus/cc65
AS65    = ca65
LD65    = ld65
CC65    = cc65 -I $(BDIR)/include

SRCS	= dos.s mmc.s spi.s

all:	dos.bin
	
dos.bin:	$(SRCS) Makefile config.ld
	$(AS65) -D DEBUG=0 -l $<
	$(LD65) -C config.ld -vm -m dos.map dos.o
	cp $@ ../../dos
	
clean:	
	rm -f *.o *.lst *.map a.out *~

