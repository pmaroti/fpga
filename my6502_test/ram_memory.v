
module ram_memory( clk, reset, AB, DO, DI, CS, WE);

    input  clk;              // CPU clock 
    input  reset;            // reset signal
    input  [8:0] AB;   // address bus
    output [7:0] DO;  // data out, write bus
    input  [7:0] DI;  // data in
    input  CS;              // chip select
    input  WE;              // Write

    reg [7:0]ram_do;				// internal ram data out bus
    reg oe_reg; 

    (* RAM_STYLE = "block" *) 
    reg [7:0]ram_int[0:511];	// ram 512 byte

    always @(posedge clk) begin
        
        oe_reg <= CS && !WE;

        if (CS) begin
            if (WE) begin
                ram_int[AB] <= DI;
            end
            else begin
                ram_do <= ram_int[AB];
            end
        end 
    end

    assign DO = (oe_reg) ? ram_do : 8'bzzzz_zzzz;
endmodule    
