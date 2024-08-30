`include "system.v"
`include "pll.v"

module main(
	output TXD, 
	input  RXD, 
	input  CLKIN, 
	output HSYN, 
	output VSYN, 
	output [3:0]R,
	output [3:0]G,
	output [3:0]B,
	inout  [15:0]XD,
	output [15:0]XA,
	output XWE,
	output XOE,
	output XBHE,
	output XBLE,
	input  [7:0]PININ,
	output [7:0]PINOUT,
	output PWM,
	input  KCLK,
	input  KDAT
);

wire clk,pll_lock;
wire [3:0]video;
//-- Instanciar el PLL
pll
  pll1(
	.clock_in(CLKIN),
	.clock_out(clk),
	.locked(pll_lock)
	);

SYSTEM sys1(.txd(TXD), .rxd(RXD), .clk(clk), .reset(reset),
	    .hsyn(HSYN), .vsyn(VSYN), .video({B,G,R}),
		.xwe(XWE), .xoe(XOE), .xdo(xdo), .xdi(xdi), .xa(XA), .xbhe(XBHE), .xble(XBLE),
		.pinin(PININ), .pinout(PINOUT), .pwmout(PWM), .kclk(KCLK), .kdat(KDAT)
);


wire kclk,kdat;

wire [15:0]xdi;
wire [7:0]xdo;

// Circuito de reset interno (Hay que esperar que el PLL funcione)
wire reset;
reg [2:0]cnt=3'b111;
assign reset=(cnt!=0);

always @(posedge VSYN) cnt<=reset ? cnt-1: cnt;

//////////////////////////////////////////////////////
// Triestados de memoria externa
wire oe;
assign oe=XOE; // Ojo, XOE está activo en bajo => escritura en alto

assign XD = oe ? {xdo,xdo} : 16'hZ;
assign xdi =XD;

endmodule


