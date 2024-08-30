#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define FCPU	(25e6)
#define FS	(FCPU/762.0)

main()
{
	int i,fdds;
	double f,df;

	// Tabla de frecuencias de notas

	f=440;
	df=1.059463094;

	for (i=0;i<9;i++) f/=df;	// Frecuencia del DO inicial

	printf("fnotas:\n\t.word ");
	for (i=0;i<12;i++) {
		fdds=f*65536.0/FS+0.5;
		f*=df;
		//printf("%d %f %d\n",i,f,fdds);
		printf("%d%c",fdds,(i==11)?'\n':',');
	}
	printf("\t.word ");
	for (i=0;i<12;i++) {
		fdds=f*65536.0/FS+0.5;
		f*=df;
		//printf("%d %f %d\n",i,f,fdds);
		printf("%d%c",fdds,(i==11)?'\n':',');
	}

	// Teclado

	#define SCBAS	(0)
	#define SCMAX	(0x61)
	unsigned char sc[SCMAX-SCBAS+1];

	printf("\n\tSCBAS = $%02x\n",SCBAS);
	printf("\tSCMAX = $%02x\n",SCMAX);
	printf("keyscan:\n");

	for (i=0;i<sizeof(sc);i++) sc[i]=0;

	sc[0x61-SCBAS]=1;	// > - DO
	sc[0x1C-SCBAS]=2;	// A - DO#
	sc[0x1A-SCBAS]=3;	// Z - RE
	sc[0x1B-SCBAS]=4;	// S - RE#
	sc[0x22-SCBAS]=5;	// X - MI
	sc[0x21-SCBAS]=6;	// C - FA
	sc[0x2B-SCBAS]=7;	// F - FA#
	sc[0x2A-SCBAS]=8;	// V - SOL
	sc[0x34-SCBAS]=9;	// G - SOL#
	sc[0x32-SCBAS]=10;	// B - LA (440Hz)
	sc[0x33-SCBAS]=11;	// H - LA#
	sc[0x31-SCBAS]=12;	// N - SI

	sc[0x35-SCBAS]=13;	// Y - DO
	sc[0x3D-SCBAS]=14;	// 7 - DO#
	sc[0x3C-SCBAS]=15;	// U - RE
	sc[(0x3E)-SCBAS]=16;	// 8 - RE#
	sc[0x43-SCBAS]=17;	// I - MI
	sc[0x44-SCBAS]=18;	// O - FA
	sc[0x45-SCBAS]=19;	// 0 - FA#
	sc[0x4D-SCBAS]=20;	// P - SOL
	sc[(0x4E)-SCBAS]=21;	// ' - SOL#
	sc[0x54-SCBAS]=22;	// ^ - LA
	sc[0x55-SCBAS]=23;	// ¡ - LA#
	sc[0x5B-SCBAS]=24;	// + - SI

	for (i=0;i<=SCMAX-SCBAS;i++) {
		if ((i&15)==0) printf("\t.byte ");
		printf("%d%c",sc[i],((i&15)==15 || i==(SCMAX-SCBAS))?'\n':',');
	}
	printf("\n");

	return 0;
}
