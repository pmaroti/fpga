module memory(
  input clk, 
  input [8:0] AB,
  input WE,
  input CS,
  input CS_o, 
  input [7:0] DI,
  output wire [7:0] DO 
);

  reg [7:0] prog_mem [511:0];
  integer i;
  reg [7:0] data_out = 8'hea;

  assign DO = (CS_o) ? data_out : 8'bz;

  initial begin

    for (i = 0; i < 512; i++) begin
        prog_mem[i] <= 8'b00000000;
    end

    prog_mem[16'h00] <= 8'hA9; // LDA #0
    prog_mem[16'h01] <= 8'h00;

    prog_mem[16'h02] <= 8'h8d; // STA $0020
    prog_mem[16'h03] <= 8'h20;
    prog_mem[16'h04] <= 8'h00;

    prog_mem[16'h05] <= 8'h8d; // STA $0010
    prog_mem[16'h06] <= 8'h10;
    prog_mem[16'h07] <= 8'h00;

    prog_mem[16'h08] <= 8'h69; // ADC #1
    prog_mem[16'h09] <= 8'h01;

    prog_mem[16'h0A] <= 8'h4c; // JMP $AA04
    prog_mem[16'h0B] <= 8'h02;
    prog_mem[16'h0C] <= 8'hAA;

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