2 REM  16-COLOR MODE, KEYBOARD INTERRUPT ENABLED
3 POKE -8189,3
4 REM  CLEAR SCREEN CALL
5 CALL -241
7 GOSUB 300
10 FOR Y=0 TO 199
20 FOR X=0 TO 255
30 CA=(X-192)*0.010
40 CB=(Y-100)*0.010
50 A=CA
60 B=CB
61 T=A+1
65 IF (T*T+B*B)<0.0625 GOTO 140
66 REM {q*(q + x - 1/4) < 1/4*y^2, where q = (x - 1/4)^2 + y^2}
67 T=(A-0.25)*(A-0.25)+B*B
68 IF T*(T+A-0.25)<0.25*B*B GOTO 140
70 FOR I=0 TO 32
80 T=A*A-B*B+CA
90 B=2*A*B+CB
100 A=T
110 IF (A*A+B*B)>4 GOTO 160
120 NEXT I
140 I=0
160 POKE 528,X
170 POKE 529,Y
175 POKE 530,I
179 REM  PUTPIXEL4 CALL
180 CALL -223
200 NEXT X
210 NEXT Y
220 END

300 REM GREYSCALE PALETTE
301 FOR I=0 TO 15
302 R=I
304 G=I
306 B=I
310 POKE -8192+5,R+G*16
320 POKE -8192+6,B+I*16
330 NEXT I
335 POKE -8192+1,0
340 RETURN
