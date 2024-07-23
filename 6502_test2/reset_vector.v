module resetvector(
  input clk, 
  input [1:0] AB,
  input WE,
  input CS,
  input CS_o, 
  output wire [7:0] DO
);

  reg [7:0] data_out = 55;

  assign DO = (CS_o) ? data_out : 8'bz;

  always @(posedge clk) begin
    $display("reset_addr: %b", AB);
    if (~WE & CS) begin
    case (AB)
        2'b00: data_out <= 8'h00;
        2'b01: data_out <= 8'hAA;
    endcase
    end 
  end

endmodule