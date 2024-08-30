#include <stdlib.h>
#include <stdio.h>

main(int argc, char **argv)
{
        int i,j;
        static unsigned char buf[65536];
		FILE *fp;

		if ((fp=fopen(argv[1],"rb"))==NULL) exit(1);
		j=fread(&buf[8],1,65536-8,fp);
		fclose(fp);

		printf("%d bytes\n",j);

		buf[0]=0xB0; buf[1]=0xCA;
		buf[2]=0x00; buf[3]=0x03;
		buf[4]=0x00; buf[5]=0x03;
		buf[6]=j&0xff; buf[7]=j>>8;

		if ((fp=fopen("out.bin","wb"))==NULL) exit(1);
		fwrite(buf,1,8+j,fp);
		fclose(fp);
		return 0;
}
