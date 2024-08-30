MEMORY {
           RAM0:  start = $100-32, size = 32;
           RAM1:  start = $E000-$700-$20C, size = $20C;
           ROM1:  start = $E000-$708, size = $708, fillval=$ff, file="dos.bin";
}

SEGMENTS {
        CODE:   load = ROM1, type = ro;
        RODATA: load = ROM1, type = ro;
	    ZEROPAGE: load= RAM0, type = zp;
        DATA:   load = RAM1, type = rw;
        BSS:    load = RAM1, type = bss, define = yes;
}
       
