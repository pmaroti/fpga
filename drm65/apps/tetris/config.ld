MEMORY {
           RAM0:  start = $0030, size = $100-$30;
           RAM1:  start = $300, size = $4000-$300;
}

SEGMENTS {
	    ZEROPAGE: load= RAM0, type = zp;
		ZPSAVE: load= RAM0, type = zp;
        CODE:   load = RAM1, type = ro;
        RODATA: load = RAM1, type = ro;
		STARTUP: load = RAM1, type = ro;
		TAPEHDR: load = RAM1, type = ro;
		INIT:   load = RAM1, type = ro;
        DATA:   load = RAM1, type = rw;
        BSS:    load = RAM1, type = bss, define = yes;
}
       
