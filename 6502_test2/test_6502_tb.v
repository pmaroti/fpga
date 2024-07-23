`define TEST
module test();

  test_6502 system_6502( clk, led, clk_cpu);
  reg clk=0;
  wire [5:0] led;
  wire clk_cpu;

  always
    #1  clk = ~clk;

  initial begin
    #400 $finish;
  end

  initial begin
    $dumpfile("6502_test.vcd");
    $dumpvars(0, test);
  end
endmodule