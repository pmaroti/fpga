#include <stdlib.h>
#include <stdio.h>

main(int argc,char **argv)
{
    int i,j;
    char *p,*p0,*pp,buf[256],eti[256];
    FILE *fp;
    
    if ((fp=fopen(argv[1],"r"))==NULL) exit(1);
    
    for (;;) {
        fgets(buf,255,fp);
	if (feof(fp)) break;
        if (buf[0]==';') {
		printf("%s",buf); // comentario
		continue;
	}
	if (buf[0]==' ' || buf[0]=='\t' || buf[0]=='\n' || buf[0]=='\r') {
		printf("%s",buf); //Sin etiqueta
		continue;
	}
	p=buf;
	pp=eti;
	while (*p!=' ' && *p!='\t' && *p!='\r' && *p!='\n') *pp++=*p++;
	*pp=0;
	p0=p;
	while (*p==' ' || *p=='\t' && *p) p++;
	if (*p=='=') {
		printf("%s",buf);	// Asignacion de etiqueta
		continue;
	}
	printf("%s:%s",eti,p0);
	
    }
    fclose (fp);
    
}
