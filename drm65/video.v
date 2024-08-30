// Generación de video compatible con VGA
// tiempos del modo VESA 640x480
// aunque nuestra resolución nativa es de 512x400

module video ( 
	input clk,		// clock input @24MHz
	input [15:0]d,	// datos leídos de memoria
	output [15:0]a,	// dirección de memoria para leer
	input [11:0]pald,	// datos para paleta
	input [3:0]pala,	// dirección para paleta
	input palwr,		// escritura en paleta
	output rd,		// lectura de memoria si 1
	output hsyn,	// sincronismo horizontal
	output vsyn,	// sincronismo vertical
	output [11:0]video,	// Salida de video (12 bits/pixel)
	input modo,		// Monocromo / color
	input [3:0]border,	// índice de paleta para borde
	output [9:0]hc	// Salida para PWM
);

reg [9:0]hc=0;	// Contador horizontal
reg hsyn=1;
wire hde;
reg hblk=0;

always @(posedge clk) begin
	if (hc==10'd799) hc<=0; else hc<=hc+1;
	if (hc==10'd591) hsyn<=0;
	if (hc==10'd687) hsyn<=1;
	if (hc==10'd575) hblk<=1;
	if (hc==10'd735) hblk<=0;
	
end

assign hde=~hc[9];

reg [9:0]vc=0;	// Contador vertical
reg vsyn=1;
reg vde=1;
reg vblk=0;

always @(negedge hblk) begin
	if (vc==10'd524) begin vc<=0; vde<=1; end else vc<=vc+1;
	if (vc==10'd449) vsyn<=0;
	if (vc==10'd451) vsyn<=1;
	if (vc==10'd399) vde<=0;
	if (vc==10'd439) vblk<=1;
	if (vc==10'd484) vblk<=0;
end

// Blank
wire blk;
assign blk = hblk|vblk;

// Data valid, Read
wire dv;
assign dv=hde&vde;
assign rd= modo ? (dv&(~hc[2])&(~hc[1])&( hc[0]))			// 1 de cada 8 ciclos
				: (dv&(~hc[3])&(~hc[2])&(~hc[1])&( hc[0])); // 1 de cada 16 ciclos

// Direcciones
assign a = modo ?{2'b00,vc[8:1],hc[8:3]} 	// 1/4 de los pixels, 2 pixels/byte
			    :{2'b00,vc[8:0],hc[8:4]};	// todos los pixels, 8 pixels/byte

// Desplazamiento
reg [15:0]vshift;

always @(posedge clk) begin
	vshift <= rd ? {d[7:0],d[15:8]} : 
			  (modo ? (hc[0]? {vshift[11:0],4'bxxxx} : vshift) : {vshift[14:0],1'bx});
end
reg	[1:0]ddv=0;		// DV retrasado 
reg [1:0]dblk=0;	// blk retrasado
always @(posedge clk) begin
	ddv<={ddv[0],dv};
	dblk<={dblk[0],blk};
end
wire [3:0]pixel;
assign pixel = ddv[1] ? (modo ? vshift[15:12]: (vshift[15]?4'b1111:4'b0000)) : border;

// Paleta de color
reg [11:0]palette[0:15];
initial begin //$readmemh("pal.hex", palette);
	palette[0]=12'h000;
	palette[1]=12'h00A;
	palette[2]=12'h0A0;
	palette[3]=12'h0AA;
	palette[4]=12'hA00;
	palette[5]=12'hA0A;
	palette[6]=12'hAA0;
	palette[7]=12'hAAA;
	palette[8]=12'h555;
	palette[9]=12'h55F;
	palette[10]=12'h5F5;
	palette[11]=12'h5FF;
	palette[12]=12'hF55;
	palette[13]=12'hF5F;
	palette[14]=12'hFF5;
	palette[15]=12'hFFF;
end

reg [11:0]palo;
always @(posedge clk) begin
	if (palwr) palette[pala]<=pald;
	palo<=palette[pixel];
end

assign video = dblk[1]? 12'h000: palo;

endmodule

