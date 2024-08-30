CC      = gcc
CFLAGS  = -O2 -w -DLSB_FIRST -DDEBUG 

BDIR    = /home/jesus/cc65
AS65    = ca65
LD65    = ld65
CC65    = cc65 -I $(BDIR)/include

SRCS	= nrom.s dissa.s irqbrk.s video.s

all:	nrom.bin reboot.bin load.bin
	
nrom.bin:	$(SRCS) Makefile nconfig.ld reboot.bin
	$(AS65) -D DEBUG=0 -l $<
	$(LD65) -C nconfig.ld -vm -m nrom.map nrom.o
	grep endtxt nrom.map
	./tovhex $@ ../out.hex
	cat reboot.bin $@ >../nrom


reboot.bin:	reboot.asm
	../../../proy/bender/xa-2.3.5/xa $< -o $@

load.bin:	load.asm
	../../../proy/bender/xa-2.3.5/xa $< -o $@

clean:	
	rm -f *.o *.lst *.map a.out *~

