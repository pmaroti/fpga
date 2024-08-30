MEMORY {
           RAM1:  start = $0000, size = $E000;
           ROM1:  start = $DFF3-6, size = $2000+13+6, fillval=$ff, file="nrom_dfed.bin";
}

SEGMENTS {
            CODE:   load = ROM1, type = ro;
	    INIT:   load = ROM1, type = ro;
            RODATA: load = ROM1, type = ro;
	    VECTORS: load = ROM1, type = ro, start = $FFFA;
	    ZEROPAGE: load= RAM1, type = zp;
            DATA:   load = RAM1, type = rw, start = $D000-512-11;
            BSS:    load = RAM1, type = bss, define = yes;
}
       
