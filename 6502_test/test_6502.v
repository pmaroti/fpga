module test_6502(
  input clk, 
  output reg [5:0] led,
  output clk_o 
);

  reg reset=1;
  wire [15:0] AB;
  reg [7:0] DI;
  wire [7:0] DO;
  wire WE;
  reg IRQ = 0;
  reg NMI = 0;
  reg RDY = 1;
  reg clk_cpu = 0;

  assign clk_o = clk_cpu;

  cpu my_6502( clk_cpu, reset, AB, DI, DO, WE, IRQ, NMI, RDY );

  localparam CLKDIV = 1350000;
  localparam reset_del = 2;
  reg [7:0] reset_cntr = 0;
  reg [23:0] counter = 0;


  always @(posedge clk) begin
    if (counter == CLKDIV) begin
      clk_cpu = clk_cpu ^ 1'b1;
      counter <= 0;
    end else begin
      counter <= counter + 24'b1;
    end 
  end

  always @(posedge clk_cpu) begin
    if (reset) begin
      if (reset_cntr == reset_del) begin
        reset = 0;
      end
      reset_cntr <= reset_cntr + 8'b1;
    end
  end

  always @(posedge clk_cpu) begin
    case( WE ) 
      1'b0 : case( AB )
          16'hFFFC: DI <= 8'h00;
          16'hFFFD: DI <= 8'hAA; // reset vector

          16'hAA00: DI <= 8'hA9; //       LDA #0
          16'hAA01: DI <= 8'h00; 

          16'hAA02: DI <= 8'h8D; // back: STA $4000
          16'hAA03: DI <= 8'h00; 
          16'hAA04: DI <= 8'h40; 

          16'hAA05: DI <= 8'h69; //       ADC #1
          16'hAA06: DI <= 8'h01;

          16'hAA07: DI <= 8'h4C; //       JMP back
          16'hAA08: DI <= 8'h02;
          16'hAA09: DI <= 8'hAA;

          16'hAA0A: DI <= 8'hEA; //       NOP

          default:  DI <= 8'hEA; //       NOP
        endcase	
      default : if (AB == 16'h4000) begin
          led <= DO;
      end
    endcase
  end

endmodule