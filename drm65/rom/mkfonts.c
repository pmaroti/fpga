#include <stdlib.h>
#include <stdio.h>

unsigned char font8x16[]=
#include "iso01a-8x16.hex"

unsigned char font8x8[]=
#include "iso01a-8x8.hex"

#include "font5x7.h"

unsigned char f68[96][8];

main()
{
	int i,j,k,d;
	unsigned char *p;
	FILE *fp;
	
	if ((fp=fopen("font8x16.inc","w"))==NULL) exit(1);
	fprintf(fp,"\t.export font8x16\nfont8x16:\n");
	for (i=32*16;i<(128*16);i+=16) {
		fprintf(fp,"\t.byte ");
		for (j=0;j<16;j++) {
			if (j==8) fprintf(fp," ");
			fprintf(fp,"$%02X",font8x16[i+j]);
			fprintf(fp,(j==15)?"\n":",");
		}
	}
	fclose(fp);

	if ((fp=fopen("font8x8.inc","w"))==NULL) exit(1);
	fprintf(fp,"\t.export font8x8\nfont8x8:\n");
	for (i=32*8;i<(128*8);i+=16) {
		fprintf(fp,"\t.byte ");
		for (j=0;j<16;j++) {
			if (j==8) fprintf(fp," ");
			fprintf(fp,"$%02X",font8x8[i+j]);
			fprintf(fp,(j==15)?"\n":",");
		}
	}
	fclose(fp);

	for (i=0;i<96;i++) {
		for (j=0;j<8;j++) {
			d=0;
			for (k=0;k<5;k++) {
				if ((font5x7[i][k]>>(j))&1) d|=1<<(7-k);
			}
			f68[i][j]=d;
		}
	}


	p=(unsigned char *)f68;
	if ((fp=fopen("font6x8.inc","w"))==NULL) exit(1);
	fprintf(fp,"\t.export font6x8\nfont6x8:\n");
	for (i=0;i<sizeof(f68);i+=16) {
		fprintf(fp,"\t.byte ");
		for (j=0;j<16;j++) {
			if (j==8) fprintf(fp," ");
			fprintf(fp,"$%02X",p[i+j]);
			fprintf(fp,(j==15)?"\n":",");
		}
	}
	fclose(fp);

}
