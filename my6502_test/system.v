`include "cpu6502.v"
`include "rom_memory.v"
`include "ram_memory.v"
`include "uart_chip.v"

// external connections for the system
module system (
	input clk,
	output [5:0]led,
	input uartRx

);

// CPU section
	wire [15:0]ca;
	wire [7:0]cdi;
	wire [7:0]cdo;
	wire cclk;
	reg reset=1;
	reg irq=0;
	wire we;

	cpu6502 cpu1( 
		.AB(ca), 			// CPU address bus
		.DO(cdo),			// CPU Data out bus
		.WE(we),			// Write enable (active high)
		.DI(cdi),			// CPU Data in bus
		.clk(cclk),			// CPU clock
		.reset(reset),		// CPU reset (active high)
		.IRQ(irq), 			// CPU interrupt (active high)
		.NMI(1'b1),			// CPU nmi (active low???)
		.RDY(1'b1) 			// CPU ready (active low???)
	);

// Memory section
	wire csirom;
	wire csiram;
	wire csiled;
	wire csiuart;

	rom_memory rom1(
		.clk(cclk), 
		.reset(reset), 
		.AB(ca[7:0]), 
		.DO(cdi), 
		.CS(csirom),
		.WE(we)
	);

	ram_memory ram1(
		.clk(cclk), 
		.reset(reset), 
		.AB(ca[8:0]), 
		.DO(cdi), 
		.DI(cdo),
		.CS(csiram),
		.WE(we)
	);

	uart_chip uart1(
		.clk(cclk), 
		.reset(reset), 
		.AB(ca[7:0]), 
		.DO(cdi), 
		.DI(cdo), 
		.CS(csiuart), 
		.WE(we),
		.uartRx(uartRx)
	);


// clock section
	assign cclk = clk;	

// address decoding for "chip select lines"
	assign csirom  = (ca[15:8] == 8'hFF) ? 1'b1 : 1'b0; 		// FF00-FFFF
	assign csiram  = (ca[15:9] == 7'b0000_000) ? 1'b1 : 1'b0;	// 0000-0100
	assign csiled  = (ca[15:8] == 8'h10) ? 1'b1 : 1'b0; 		// 1000-10FF
	assign csiuart = (ca[15:8] == 8'h20) ? 1'b1 : 1'b0; 		// 2000-20FF


// IO section
	reg [5:0]ledreg;
	assign led = ~ledreg;

	always @(posedge cclk) begin

		if (reset) begin
			ledreg <= 8'h00;
		end

		if (csiled) begin
			if (we) begin
				ledreg <= cdo[5:0];
			end
		end 
	end

// reset signal section
	localparam RESET_TIME = 5;
	reg [7:0] reset_cntr = 0;

	always @(posedge cclk) begin
		if (reset) begin
			if (reset_cntr == RESET_TIME) begin
				reset <= 0;
			end
			reset_cntr <= reset_cntr + 8'b1;
		end
	end

endmodule