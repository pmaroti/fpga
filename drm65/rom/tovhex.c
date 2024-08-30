#include <stdlib.h>
#include <stdio.h>


#define ROMBASE	(0x0000) 		
#define ROMSIZE (0x2000)

unsigned char mem[ROMSIZE];

main(int argc, char **argv)
{
	int i,n;
	FILE *fp;

	if ((fp=fopen(argv[1],"rb"))==NULL) exit(1);
	n=fread(mem,1,ROMSIZE,fp);
	fclose(fp);

	if ((fp=fopen(argv[2],"wb"))==NULL) exit(1);
	fprintf(fp,"@%04X\n",0);
	for (i=0;i<n;i++) fprintf(fp,"%02X\n",mem[i]);
	fclose(fp);
	return 0;
}

