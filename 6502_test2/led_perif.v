module led_perif(
  input clk, 
  input [1:0] AB,
  input WE,
  input CS,
  input CS_o, 
  input [7:0] DI,
  output wire [7:0] DO,
  output wire [5:0] led
);

  reg [7:0] ledval=0;

  assign DO = (CS_o) ? ledval : 8'bz;

  assign led = ~ledval;

  always @(posedge clk) begin
    $display("led_val: %h", DI);
    if (WE & CS) begin
        ledval = DI;
    end 
  end

endmodule