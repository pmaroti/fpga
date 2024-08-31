`define SIM 1
`include "system.v"

module test();

  system system_6502(clk, leds, uartRx);
  reg clk=0;
  wire [7:0]leds;
  reg uartRx=1;

  always
    #1  clk = ~clk;

  initial begin
    #500 $finish;
  end

  initial begin
    $dumpfile("system_test.vcd");
    $dumpvars(0, test);
  end
endmodule