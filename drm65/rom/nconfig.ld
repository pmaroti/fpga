MEMORY {
           RAM0:  start = $0000, size = $100;
           RAM1:  start = $200, size = $E000-$200;
           ROM1:  start = $E000, size = $2000, fillval=$ff, file="nrom.bin";
}

SEGMENTS {
        CODE:   load = ROM1, type = ro;
	    INIT:   load = ROM1, type = ro;
        RODATA: load = ROM1, type = ro;
		JUMPT:	load = ROM1, type = ro, start = $FF00;
	    VECTORS: load = ROM1, type = ro, start = $FFFA;
	    ZEROPAGE: load= RAM0, type = zp;
        DATA:   load = RAM1, type = rw;
        BSS:    load = RAM1, type = bss, define = yes;
}
       
