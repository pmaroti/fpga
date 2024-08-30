all:	snd.bin 

snd.bin:	snd.asm tbls.inc
	../../../../../proy/bender/xa-2.3.5/xa $< -o $@
	cp $@ ../../snd

tbls.inc:	mktbls
	./mktbls >tbls.inc

mktbls:	mktbls.c
	gcc -w -O2 -o $@ $<

