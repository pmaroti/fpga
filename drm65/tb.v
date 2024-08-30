//-------------------------------------------------------------------
//-- Banco de pruebas 
//-------------------------------------------------------------------
`include "system.v"

module tb();

//-- Registos con señales de entrada
reg clk;
wire txd;
reg rxd;
reg reset;

//-- Instanciamos 
wire [15:0]xa;
wire [7:0]xdo;
wire [15:0]xdi;
wire oe,we,ble,bhe;

SYSTEM sys(.txd(txd), .clk(clk), .rxd(rxd), .reset(reset),
			.xwe(we), .xoe(oe),.xa(xa),.xdo(xdo),.xdi(xdi),
			.xble(ble), .xbhe(bhe),
			.kclk(1'b1)
);
exRAM XRAM(.addr(xa), .data_in(xdo), .data_out(xdi), .oe(oe), .we(we),
			.bhe(bhe), .ble(ble) );

always #5 clk=~clk;

//-- Proceso al inicio
initial begin
	//-- Fichero donde almacenar los resultados
	$dumpfile("tb.vcd");
	$dumpvars(0, tb);

	clk=0;
	reset=1;
	rxd=1;
	#50 reset=0;
	#5000 rxd=0;
	#4160 rxd=1; 
	//# 319 $display("FIN de la simulacion");
	# 100000 $finish;
end

endmodule

//----------------------------------------------------------------------------
//-- Memoria RAM asíncrona
//----------------------------------------------------------------------------

module exRAM (        
    input wire [15:0] addr,      //-- Direcciones
    input wire [7:0] data_in,   //-- Dato de entrada
    output reg [15:0] data_out,   //-- Dato a escribir
	input wire	oe,
	input wire  we,
	input wire bhe,
    input wire ble
);
  //-- Memoria
  reg [7: 0] ramh [0: 16'hffff];
  reg [7: 0] raml [0: 16'hffff];

  //-- Escritura en la memoria
  always @(negedge we) begin
    if (~ble) raml[addr] <= data_in;
    if (~bhe) ramh[addr] <= data_in;
  end

  always @(negedge oe) begin
    data_out <= {ramh[addr],raml[addr]};
  end
endmodule

