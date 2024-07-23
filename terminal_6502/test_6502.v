module test_6502(
  input clk, 
  output reg [5:0] led,
  output clk_o dsa
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
  //localparam CLKDIV = 1;
  localparam reset_del = 2;
  reg [7:0] reset_cntr = 0;
  reg [23:0] counter = 0;

  reg [7:0] prog_mem [511:0];
  integer i;


  initial begin

    for (i = 0; i < 512; i++) begin
        prog_mem[i] <= 8'b00000000;
    end

    prog_mem[16'h00] <= 8'hA9;
    prog_mem[16'h01] <= 8'h00;

    prog_mem[16'h02] <= 8'h8D;
    prog_mem[16'h03] <= 8'h00;
    prog_mem[16'h04] <= 8'h40;

    prog_mem[16'h05] <= 8'h69;
    prog_mem[16'h06] <= 8'h01;

    prog_mem[16'h07] <= 8'h4C;
    prog_mem[16'h08] <= 8'h02;
    prog_mem[16'h09] <= 8'hAA;

  end

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
    $display("addr: %b", AB[15:8]);
    case( WE ) 
      1'b0 : casex (AB)
        16'b1010_1010_????_???? : begin
           DI <= prog_mem[ (AB & 16'h00FF) ];
           $display ("progmem read. %h", (AB & 16'h00FF));           
        end
        16'hFFFC : DI <= 8'h00;
        16'hFFFD : DI <= 8'hAA;
      endcase
      default :
        casex (AB)
          16'h4000 : led <= ~DO;
          16'b1010_1010_????_???? : prog_mem[ (AB & 16'hFF) ] <= DO;
        endcase
    endcase
  end

endmodule