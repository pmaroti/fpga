MEMORY {
           RAM1:  start = $0000, size = $B700;
           ROM1:  start = $B700-8, size = $2900+8, fillval=$ff, file="basic.bin";           
}

SEGMENTS {
        CODE:   load = ROM1, type = ro;
        RODATA: load = ROM1, type = ro;
	    ZEROPAGE: load= RAM1, type = zp;
        DATA:   load = RAM1, type = rw, start = $300;
        BSS:    load = RAM1, type = bss, define = yes;
}
       
