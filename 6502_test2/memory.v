module memory 
#(
  parameter isROM = 1'b0,
  parameter MEMSIZE = 512
)
(
  input clk, 
  input [8:0] AB,
  input WE,
  input CS,
  input CS_o, 
  input [7:0] DI,
  output wire [7:0] DO 
);

  reg [7:0] prog_mem [(MEMSIZE-1):0];
  integer i;
  reg [7:0] data_out = 8'hea;

  assign DO = (CS_o) ? data_out : 8'bz;

  initial begin
    if (isROM == 1'b1)
      $readmemh("rom.hex", prog_mem);
  end

  always @(posedge clk) begin
    $display("mem addr: %b", AB);
    if (~WE & CS) begin
      data_out <= prog_mem[(AB)];
    end else begin
      prog_mem[(AB)] <= DI;
    end
end

endmodule