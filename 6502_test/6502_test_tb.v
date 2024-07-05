module test();
  reg clk = 0;
  reg reset = 0;
  wire [15:0] AB;
  reg [7:0] DI;
  wire [7:0] DO;
  wire WE = 0;
  reg IRQ = 0;
  reg NMI = 0;
  reg RDY = 1;
  reg [5:0] OUTLED;

  cpu myCPU( clk, reset, AB, DI, DO, WE, IRQ, NMI, RDY );

  always
    #1  clk = ~clk;

always @(posedge clk) begin
  case( WE ) 
    1'b0 : case( AB )
        16'hFFFC: DI = 8'h00;
        16'hFFFD: DI = 8'hAA; // reset vector

        16'hAA00: DI = 8'hA9;
        16'hAA01: DI = 8'h00; //LDA #0

        16'hAA02: DI = 8'h8D; // back: STA $4000
        16'hAA03: DI = 8'h00; 
        16'hAA04: DI = 8'h40; 

        16'hAA05: DI = 8'h69; //ADC #1
        16'hAA06: DI = 8'h01;

        16'hAA07: DI = 8'hD0; //BNE back
        16'hAA08: DI = 8'hF9;

        16'hAA09: DI = 8'hEA; // NOP

        default: DI = 8'hEA; // NOP
	    endcase	
    1'b1 : OUTLED = DO;
  endcase
end

  initial begin
    reset = 1;
    #2 reset = 0;
    #100 $finish;
  end

  initial begin
    $dumpfile("6502_test.vcd");
    $dumpvars(0, test);
  end
endmodule