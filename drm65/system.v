//--------------------------------------------------------------------
// Sistema con CPU, RAM y UART
//--------------------------------------------------------------------
`include "cpu6502.v"
//`include "uart.v"
`include "uart_simple.v"
`include "video.v"


module SYSTEM (
	input clk,
	input reset,

	output xwe,		// Bus externo: WE
	output xoe,		// Bus externo: OE
	output [15:0]xa,// Bus externo: direcciones
	output [7:0]xdo,	// Bus externo: output
	input  [15:0]xdi,	// Bus externo: input
	output xbhe,	// Bus externo: Byte alto
	output xble,	// Bus externo: byte bajo

	output txd,
	input rxd,

	output hsyn,
	output vsyn,
	output [11:0]video,

	input  [7:0]pinin,
	output [7:0]pinout,

	output	pwmout,

	input	kclk,
	input	kdat
);

/////////////////////////////// CPU ////////////////////////////////

wire cclk;
wire [15:0]ca;
wire [7:0]cdi;
wire [7:0]cdo;
wire wep;
wire irq;
wire rw;
// Ojo: todas las señales son activas en alto
cpu6502 cpu1( .AB(ca),.DO(cdo),.WE(we),.DI(cdi),.clk(cclk),.reset(reset),
	.IRQ(irq), .NMI(1'b1), .RDY(1'b1) );

assign rw = ~we;
assign cclk = clk | (vrd&csxram);	// Si video RD => cclk en alto

// decodificación de direcciones:
wire csiram, csio, csxram;

assign csxram = ~( ca[15] & ca[14] & ca[13] );	// $0000-$DFFF
assign csio   = ca[15]&ca[14]&ca[13]&(~ca[12])&(~ca[11])&(~ca[10])&	// $E000-E00F
				(~ca[9])&(~ca[8])&(~ca[7])&(~ca[6])&(~ca[5])&(~ca[4]);
assign csiram = (~csxram)&(~csio);	// $E010-$EFFF

////////////////////////////// VIDEO ///////////////////////////////
wire vrd;
wire [15:0]va;
wire hsyn;
wire vsyn;
wire palwr;
video video0( .clk(clk), .hsyn(hsyn), .vsyn(vsyn), .video(video),
			  .rd(vrd), .a(va), .d(xdi), .pald({cdo[3:0],paltmp}),.pala(cdo[7:4]),.palwr(iocsw6),
			  .modo(modovideo), .border(border), .hc(hcont) ); 

///////////////////////// RAM INTERNA //////////////////////////////
reg [7:0]ido;

reg [7:0]ram_int[0:8191];
initial $readmemh("out.hex", ram_int);
always @(posedge cclk) begin
	// Uncomment for RAM
	if (we&csiram) ram_int[ca[12:0]]<=cdo;
	ido<=ram_int[ca[12:0]];
end


/////////////////////// Entrada de datos hasta CPU ////////////////////
reg [7:0]rdo;	// para registrar datos asíncronos de XRAM e I/O
reg delcsni=0;
always @(posedge cclk) begin // RAM externa y E/S tienen que retardarse un ciclo
	rdo<= csio ? pdo: (ca[0] ? xdi[15:8] : xdi[7:0]);
	delcsni<=csxram | csio;
end

assign cdi =delcsni ? rdo : ido;

//////////////////////// Interfaz con RAM externa //////////////////

//////// MMU ///////

reg [3:0]mmu[0:6];
wire [3:0]ma=mmu[ca[15:13]];

/////// BUS //////
assign xdo = cdo;
assign xa = vrd ? va : {ma,ca[12:1]};
assign xble = (~vrd)&ca[0];
assign xbhe = (~vrd)&(~ca[0]);

assign xoe = ~( vrd | (rw&csxram) ); //~( (vrd | (rw&csxram))&(~clk) );
assign xwe = ~( (we&csxram)&(~clk) );

////////////////////////////////////////////////////////////////////
//                          PERIFERICOS
////////////////////////////////////////////////////////////////////
// Selección en escritura
wire  iocsw0 =we&csio&(~ca[3])&(~ca[2])&(~ca[1])&(~ca[0]);
wire  iocsw1 =we&csio&(~ca[3])&(~ca[2])&(~ca[1])&( ca[0]);
wire  iocsw2 =we&csio&(~ca[3])&(~ca[2])&( ca[1])&(~ca[0]);
wire  iocsw3 =we&csio&(~ca[3])&(~ca[2])&( ca[1])&( ca[0]);
wire  iocsw4 =we&csio&(~ca[3])&( ca[2])&(~ca[1])&(~ca[0]);
wire  iocsw5 =we&csio&(~ca[3])&( ca[2])&(~ca[1])&( ca[0]);
wire  iocsw6 =we&csio&(~ca[3])&( ca[2])&( ca[1])&(~ca[0]);
wire  iocsw7 =we&csio&(~ca[3])&( ca[2])&( ca[1])&( ca[0]);

wire  iocswpg=we&csio&( ca[3]);

// Strobes en lectura

wire stb0=rw&csio&(~ca[3])&(~ca[2])&(~ca[1])&(~ca[0]);
wire stb7=rw&csio&(~ca[3])&( ca[2])&( ca[1])&( ca[0]);

////////////////////////////// UART ////////////////////////////////
wire [7:0]uartdo;
wire thre,dv,fe,ove;
//UART_CORE #(.DIVISOR(217))
//	UART1(	.txd(txd), .tend(tend), .thre(thre),.d(cdo),.wr(iocsw0),
//		.q(uartdo), .dv(dv), .fe(fe), .ove(ove),
//		.rxd(rxd), .rd(stb0), .clk(clk) );

UART_core #(.DIVIDER(217))
	UART1(	.txd(txd), .txrdy(thre),.d(cdo),.wr(iocsw0),
		.q(uartdo), .rxvalid(dv), .rxframeer(fe), .rxoverr(ove), .nstop(1'b0),
		.rxd(rxd), .rd(stb0), .clk(clk) );
wire tend=1'b0;

wire irqurx,irqutx;
assign irqurx=dv&controlr[0];
assign irqutx=thre&controlr[1];

// Registros de control y status

// Registro $E002: control
// bit 0 IRQ_enable UART_RX
// bit 1 IRQ_enable UART_TX
// bit 2 IRQ_enable VSYN
// bit 3 IRQ_enable HSYN
// bit 4 IRQ delayed (for single step)
// bit 5 IRQ_clear VSYN
// bit 6 IRQ_clear HSYN
// bit 7 IRQ_clear IRQ_delayed
reg [3:0]controlr;			// solo 4 bits implementados (resto strobes)
reg [4:0]deltim=5'b11111;	// contador para retardo de IRQ
reg delirq=0;				// petición de IRQ del temporizador
always @(posedge cclk) begin
	controlr<= iocsw2 ? cdo[3:0] : controlr;
	if (iocsw2&cdo[4]) deltim<=23;
	else if (deltim!=5'b11111) deltim<=deltim-1;
	delirq<= (deltim==0) ? 1 : ((iocsw2&cdo[5]) ? 0 : delirq); 
end
// interrupciones video
reg ohsyn,ovsyn;
reg irqv=0, irqh=0;
always @(posedge cclk) begin
	irqh<=((~hsyn)&ohsyn&controlr[3]) ? 1 : ((iocsw2&cdo[7])? 0 : irqh);
	irqv<=((~vsyn)&ovsyn&controlr[2]) ? 1 : ((iocsw2&cdo[6])? 0 : irqv);
	ohsyn<=hsyn;
	ovsyn<=vsyn;
end
// Interrupciones globales
assign irq= irqurx | irqutx | irqv | irqh | delirq | irqk;

// Registros $E003-E00F
reg [3:0]border=8;
reg modovideo=0;
reg ekbi=0;
reg [7:0]pinout;
reg [7:0]pwm;
reg [7:0]paltmp;

always @(posedge cclk) begin
	border<= iocsw1  ? cdo[3:0] : border; 
	modovideo<=iocsw3 ? cdo[0] : modovideo;
	ekbi  <= iocsw3  ? cdo[1] : ekbi;
	pinout<= iocsw4  ? cdo : pinout;
	paltmp<= iocsw5  ? cdo : paltmp;
	pwm   <= iocsw7  ? cdo : pwm;
	if(iocswpg) mmu[ca[2:0]]<=cdo[3:0];
end

// PWM
wire [9:0]hcont;
reg pwmout;
always @(posedge clk) begin
	pwmout<=(~hsyn) ? 1: (((pwm==hcont[8:1])&(~hcont[9])) ? 0 : pwmout);
end

// Keyboard PS2

reg [10:0]kreg=11'h7FF;

// no se puede muestrear el reloj a la frecuencia de la CPU pues tiene
// flancos sucios (los pines no tienen histéresis). Muestreándolo cada
// 32 ciclos (o 26 en algunos casos) eliminamos los glitches.
reg krck=1;
always @(posedge hcont[4]) krck<=kclk;

reg kock=1;	// para detectar flanco de bajada
always @(posedge cclk) begin
	kock<=krck;
	kreg<=(stb7) ?11'h7FF : ( ((~krck)&kock) ? {kdat,kreg[10:1]} : kreg);
end

wire [7:0]kin;
assign kin = kreg[8:1];
wire irqk;
assign irqk=(ekbi&(~kreg[0]));

///////////////////// Multiplexado de entrada I/O /////////////////////
reg [7:0]pdo;	// No es registro
// Multiplexor de entradas de I/O
always@*
  case (ca[3:0])
      0 : pdo <=  uartdo;
      1 : pdo <=  {thre,dv,irqutx,irqurx,1'bx,tend,ove,fe};
      2 : pdo <=  {irqh,irqv,hsyn,vsyn,controlr};
      3 : pdo <=  {irqk,~kreg[0],4'bxxxx,ekbi,modovideo};
      4 : pdo <=  pinout;
	  5 : pdo <=  pinin;
      6 : pdo <=  8'bxxxxxxxx;
      7 : pdo <=  kin;
	default : pdo <={4'bxxxx,mmu[ca[2:0]]};
  endcase

endmodule


