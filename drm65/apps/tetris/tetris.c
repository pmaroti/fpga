#include <stddef.h>
#include <6502.h>


/************* Variables Globales ************/

typedef unsigned char uchar;

#define ANCHO 	10
#define ALTO	20
//#define REVERSE

uchar campo[ALTO+1][16],oldc[ALTO+1][16];
uchar pieza[4][4];

uchar piezas[7][2][4];
const uchar ptab[56]={
        1,1,1,1,        // 0 Barra
        0,0,0,0,
        2,2,2,0,        // 1 /L
        0,0,2,0,
        0,3,3,3,        // 2 L
        0,3,0,0,
        0,0,4,4,        // 3 S
        0,4,4,0,
        5,5,0,0,        // 4 /S
        0,5,5,0,
        0,6,6,6,        // 5 T
        0,0,6,0,
        0,7,7,0,        // 6 Cuadrado
        0,7,7,0
};

void init_pt(void)
{
        uchar *p,*pp,i;
        pp=(uchar *)piezas;
        p=(uchar *)ptab;
        for (i=0;i<56;i++) *pp++=*p++;
}

signed char xp,yp;	// Posición de la pieza

/************** RUTINAS asociadas al SISTEMA ****************/

static unsigned long srand;
int rand()
{
    srand=srand* 1103515245 + 12345;
    return (srand>>16)&0x7fff;
}

//uchar *video;

/*--------------- Hardware I/O ---------------*/
#define BORDER *((volatile unsigned char *)0xE001)
#define STAT1  *((volatile unsigned char *)0xE002)
#define CTRL2  *((volatile unsigned char *)0xE003)
#define PAL0   *((volatile unsigned char *)0xE005)
#define PAL1   *((volatile unsigned char *)0xE006)
#define PAGE0  *((volatile unsigned char *)0xE008)
#define PAGE1  *((volatile unsigned char *)0xE009)
#define PAGE2  *((volatile unsigned char *)0xE00A)
#define PAGE3  *((volatile unsigned char *)0xE00B)
#define PAGE4  *((volatile unsigned char *)0xE00C)
#define PAGE5  *((volatile unsigned char *)0xE00D)
#define PAGE6  *((volatile unsigned char *)0xE00E)

#define IOCHAN	*((volatile unsigned char *)0x18)

unsigned char txtx,txty;
void cout(unsigned char a);
char cinnb();
void cls();

void cout(unsigned char a)
{
    unsigned char i,d;
    unsigned char *pd,*ps;
    static const unsigned char dptab[4]  ={0x00,0x0F,0xF0,0xFF};

    pd=(unsigned char *)0x4000;
    pd=&pd[txtx*5+txty*128*16];
    ps=(unsigned char *)(0xE010+16*(a-32));
    for (i=0;i<16;i++) {
	d=*ps++;
	*pd++=dptab[d>>6];
	*pd++=dptab[(d>>4)&3];
	*pd++=dptab[(d>>2)&3];
	*pd++=dptab[d&3];
	pd=&pd[128-4];
    }
    txtx++;
}


void puts(char *p)
{
        while (*p) cout(*p++);
}

void delay16m(unsigned char n)
{
    for (;n;n--) {
	while (!(STAT1&0x10));
	while (STAT1&0x10);

	srand++;
    }
}

unsigned char posx,posy;

void prtnum(uchar x)
{
        cout('0'+x/100);
        cout('0'+(x/10)%10);
        cout('0'+x%10);
}

const unsigned char cuad[9*32]={
#include "cuadros.h"
};

void cuadro(unsigned char x,unsigned char y, unsigned char tipo)
{
    unsigned char i,j,*pd,*ps;
    x+=10; // Centrado
    pd=(unsigned char *)0x4000;
    pd=&pd[x*4+y*128*8];
    ps=(unsigned char *)&cuad[tipo*32];
    for (i=0;i<8;i++) {
		for (j=0;j<4;j++) *pd++=*ps++;
		pd=&pd[128-4];
    }
}

/**************** Rutinas del CORE del programa ***************/

signed char testpos(signed char x, signed char y)
{
	register signed char i,j;
	for (i=0;i<4;i++)
		for (j=0;j<4;j++) {
			if (x+j<0) continue;
			if (x+j>ANCHO+1) continue;
			if (y+i<0) continue;
			if (y+i>ALTO) continue;
			if (campo[y+i][x+j] && pieza[i][j]) return 1;
		}
	return 0;
}

void rota(signed char giro)
{
	register unsigned char i,j;
	uchar tmp[4][4];
	if (giro>0) {		//Giro antihorario de 90º
		for (i=0;i<4;i++)
			for (j=0;j<4;j++) tmp[3-j][i]=pieza[i][j];
		for (i=0;i<4;i++)
			for (j=0;j<4;j++) pieza[i][j]=tmp[i][j];
	}
	if (giro<0) {		//Giro horario de 90º
		for (i=0;i<4;i++)
			for (j=0;j<4;j++) tmp[j][3-i]=pieza[i][j];
		for (i=0;i<4;i++)
			for (j=0;j<4;j++) pieza[i][j]=tmp[i][j];
	}
}

void init()
{
	register unsigned char i,j;

	for (i=0;i<ALTO;i++) {
		for (j=1;j<ANCHO+1;j++) campo[i][j]=0;
		campo[i][0]=campo[i][ANCHO+1]=8;
	}
	for (j=0;j<ANCHO+2;j++) campo[i][j]=8;
	for (i=0;i<ALTO+1;i++) for(j=0;j<ANCHO+2;j++) oldc[i][j]=0xff;
	for (i=0;i<4;i++) for (j=0;j<4;j++) pieza[i][j]=0;
	xp=4; yp=-4;

	cls();
}

void display()
{
	register signed char i,j,ip,jp,ch;

	for (i=0;i<ALTO+1;i++) {
	    for (j=0;j<ANCHO+2;j++) {
		ch=0;
		if (campo[i][j]) ch=campo[i][j];
		ip=i-yp;
		if (ip>=0 && ip<4) {
		    jp=j-xp;
		    if (jp>=0 && jp<4) if (pieza[ip][jp]) ch=pieza[ip][jp];
		}
		if (oldc[i][j]!=ch) {
		    oldc[i][j]=ch;
		    cuadro(j,i,ch);
		}
	    }
	}
}

/************** Programa **************/
#define INIDEL 15	//0.5 Seg
#define DELSTEP 10	//incremento de velocidad cada DELSTEP lineas


void main()
{
    register signed char i,j,k,np,sigp,del,dl,npiezas,nlineas,max;
    unsigned char a,*p,pag[4];
    static const unsigned char mypal[32]={
    0x00, 0x00,
	0x0A, 0x10,
	0xA0, 0x20,
	0xAA, 0x30,
	0x00, 0x4A,
	0x0A, 0x5A,
	0xA0, 0x6A,
	0xAA, 0x7A,
	0x55, 0x85,
	0x5F, 0x95,
	0xF5, 0xA5,
	0xFF, 0xB5,
	0x55, 0xCF,
	0x5F, 0xDF,
	0xF5, 0xEF,
	0xFF, 0xFF
    };

    CTRL2=3;	// Modo color 
    IOCHAN=0x03; // Sin salida por UART ni video (sin cursor)
    // Copia de las páginas
    pag[0]=PAGE2;
    pag[1]=PAGE3;
    pag[2]=PAGE4;
    pag[3]=PAGE5;
    // Video a partir de los 16k (0x4000)
    PAGE2=0;
    PAGE3=1;
    PAGE4=2;
    PAGE5=3;

	// Cambia paleta de color
	for (i=0,p=(unsigned char *)mypal;i<16;i++) {
		PAL0=*p++;
		PAL1=*p++;
	}
	// Cambia borde
	BORDER=0;
	
    init_pt();
    max=0;
    while(1) {
	init();
	display();
	sigp=rand()%7;
	npiezas=nlineas=0;
        txtx=19; txty=6; puts("MAX");
        txtx=19; txty=7; prtnum(max);
	for(;;) {
		// Sacamos una pieza aleatoria
		npiezas++;
		np=sigp;
		sigp=rand()%7;
		// Dibujamos la siguiente pieza
		for (i=0;i<2;i++)
		    for(j=0;j<4;j++)
		    	cuadro(ANCHO+3+j,i,piezas[sigp][i][j]);
		// Copiamos pieza actual a su bitmap
		for (i=0;i<4;i++)
		    for (j=0;j<4;j++)
			pieza[i][j]=(i==0 || i==3)?0:piezas[np][i-1][j];
		// Posiciones iniciales
		xp=4; yp=-2;
		// Si no se puede ni empezar: Game Over
		if (testpos(xp,yp)) break;
		del=INIDEL-nlineas/DELSTEP; if (del<1) del=1; dl=del;
		for (;;) { // Bucle de caida
			np=0;
			switch(cinnb()) {
			case 'D':	// IZQUIERDA
			case 0x92:	if (!testpos(xp-1,yp)) xp--;
					np=1;
					break;
			case 'C':	// DERECHA
			case 0x93:	if (!testpos(xp+1,yp)) xp++;
					np=1;break;
			case 'A':	// ARRIBA
			case 0x90:	rota(1);
					if(testpos(xp,yp)) rota(-1);
					np=1;
					break;
			case 'B':	// ABAJO
			case ' ':
			case 0x91:	while (!testpos(xp,yp+1)) {
					    yp++;
					    display();
					    delay16m(3);
					}
					goto nuevapieza;
			case 'p':	while(cinnb()!='p') delay16m(3);
					break;
			case 'q':
			//case 27:
					goto retorno;
			}
			if (!(--dl)) {	// ABAJO
				dl=del;
				if (testpos(xp,yp+1)) break;
				yp++;
				np=1;
			}
			if (np) display();
			delay16m(3);
		}
nuevapieza:	// Añadimos la pieza al campo
		for (i=0;i<4;i++) {
		    if (yp+i>=0 && yp+i<ALTO) {
			p=&campo[yp+i][xp];
		    	for (j=0;j<4;j++) {
		    	    if (xp+j>0 && xp+j<ANCHO+1){
		    	        if (!(*p)) *p=pieza[i][j];
			    }
			    p++;
			}
		    }
		}

		// Comprobamos si hay que "quemar" alguna línea
		xp=yp=-4;
		for (i=0;i<ALTO;i++) {
		    for (j=1;j<ANCHO+1;j++) if (!campo[i][j]) break;
		    if (j==ANCHO+1) {	// Linea completa: Scroll hacia abajo
			for (j=1;j<ANCHO+1;j++)
			    for (k=i;k>=0;k--)
				campo[k][j]=(k)?campo[k-1][j]:0;
			nlineas++;
			txtx=19; txty=4;
			prtnum(nlineas);
			if (nlineas>max) {
				max=nlineas;
				txtx=19; txty=7;
                                prtnum(max);
			}
			display();
			delay16m(6);
		    }
		}
	}
	txtx=2; txty=3; puts("GAME");
	txtx=2; txty=5; puts("OVER");
	txtx=2;  txty=11; puts("press UP for new game");
    	while(1) {
	    a=cinnb();
	    if (a=='A') break;
	    if (a==0x90) break;
	    if (a=='q' || a==27) goto retorno;
	} 
    }
retorno:
    // retorno
    PAGE2=pag[0];
    PAGE3=pag[1];
    PAGE4=pag[2];
    PAGE5=pag[3];
    CTRL2=2;	// Modo monocromo
    //COLOR=0x4B;	// amarillo claro sofre azul
    IOCHAN=0xC3; 	// Con salida por UART
    return;
}
