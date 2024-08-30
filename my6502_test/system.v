// `include "cpu6502.v"

// external connections for the system
module system (
	input clk,
	output [5:0]led
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
	reg [7:0]ido;				// internal ram/rom data out bus
	(* RAM_STYLE = "block" *) 
	reg [7:0]rom_int[0:255];	// rom 256 byte
	(* RAM_STYLE = "block" *) 
	reg [7:0]ram_int[0:511];	// ram 256 byte zeropage+ full 256 byte stack

// IO section
	reg [5:0]ledreg;

	assign csirom = (ca[15:8] == 8'hFF) ? 1'b1 : 1'b0; // chip select for internal rom (active high)
	assign csiram = (ca[15:9] == 7'b0000_000) ? 1'b1 : 1'b0; // chip select for internal ram (active high) 0x0000-0x01FF
	assign csiled = (ca == 16'h1000) ? 1'b1 : 1'b0; // chip select for internal ram (active high)

	reg csi_reg=0;		// chip select register based on adress bus active id rom or ram adressed

	assign led = ~ledreg;

	always @(posedge cclk) begin
		if (reset) ledreg = 8'h00;
		if (csiled) begin
			if (we) ledreg = cdo[5:0];
		end else begin
			if (csirom) begin
				ido <= rom_int[ca[7:0]];
			end else if (csiram) begin
				if (we) 
					ram_int[ca[7:0]]<=cdo;
				else
					ido <= ram_int[ca[7:0]];
			end
			csi_reg <= csirom | csiram;
		end
	end

	assign cdi = csi_reg ? ido : 8'bzzzz_zzzz;

	initial $readmemh("rom.hex", rom_int);		//rom date from compiled program

// clock section
	assign cclk = clk;

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