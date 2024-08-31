
module rom_memory ( clk, reset, AB, DO, CS, WE);

    input  clk;              // CPU clock 
    input  reset;            // reset signal
    input  [7:0] AB;   // address bus
    output [7:0] DO;        // data out, write bus
    input  CS;              // chip select
    input  WE;              // write?

    reg [7:0]rom_do;				// internal rom data out bus
    reg oe_reg;

    (* RAM_STYLE = "block" *) 
    reg [7:0]rom_int[0:255];	// rom 256 byte

    always @(posedge clk) begin
        
        oe_reg <= CS && !WE;

        if (CS) begin
            rom_do <= rom_int[AB];
        end
    end

    assign DO = (oe_reg) ? rom_do : 8'bzzzz_zzzz;

    initial $readmemh("rom.hex", rom_int);  //rom date from compiled program
endmodule    