#include <stdlib.h>
#include <stdio.h>

unsigned char dat[8][8];

void cuadro(int col)
{
	int i,j,d;

	for (i=0;i<8;i++) for (j=0;j<8;j++) dat[i][j]=col;
	if (col) {
		for (i=0;i<7;i++) {
			dat[0][i]|=0x8;
			dat[i][0]|=0x8;
			dat[7][1+i]=8;
			dat[i][7]=8;
			if (i<3) {
				dat[2+i][5]|=0x8;
				dat[5][3+i]|=0x8;
				dat[2][2+i]=8;
				dat[3+i][2]=8;
			}
		}
		dat[i][0]|=0x8;
		dat[2][2+3]=8;
	}

	for (i=0;i<8;i++) {
		for (j=0;j<8;j+=2) {
			d=(dat[i][j]<<4)|dat[i][j+1];
			printf("0x%02X,",d);
		}
		printf("\n");
	}

}



main()
{

	int i;

	for (i=0;i<8;i++) {
		printf("// color %d\n",i);
		cuadro(i);
		printf("\n");
	}

	printf("// color 8\n");
	printf("0x33,0x33,0x33,0x33,\n");
	printf("0x33,0x88,0x88,0x33,\n");
	printf("0x38,0x38,0x83,0x83,\n");
	printf("0x38,0x83,0x88,0x83,\n");
	printf("0x38,0x88,0x38,0x83,\n");
	printf("0x38,0x38,0x83,0x83,\n");
	printf("0x33,0x88,0x88,0x33,\n");
	printf("0x33,0x33,0x33,0x33\n");

}
