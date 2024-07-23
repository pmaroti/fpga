module test_6502(
  input clk, 
  output wire [5:0] led,
  output clk_o,
  output uartTx
);

  reg reset=1;
  wire [15:0] AB;
  wire [7:0] DI;
  wire [7:0] DO;
  wire WE;
  reg IRQ = 0;
  reg NMI = 0;
  reg RDY = 1;
  reg clk_cpu = 0;

  reg CS_mem_o;
  wire CS_mem;

  reg CS_resetvector_o;
  wire CS_resetvector;

  reg CS_led_perif_o;
  wire CS_led_perif;

  reg CS_uart_perif_o;
  wire CS_uart_perif;


  cpu my_6502( 
    .clk(clk_cpu),
    .reset(reset), 
    .AB(AB),
    .DI(DI),
    .DO(DO),
    .WE(WE),
    .IRQ(IRQ), 
    .NMI(NMI),
    .RDY(RDY) 
  );
  memory my_memory( 
    .clk(clk_cpu),
    .AB(AB[8:0]),
    .WE(WE),
    .CS(CS_mem),
    .CS_o(CS_mem_o),
    .DI(DO), 
    .DO(DI)
  );

  resetvector my_reset_vector( 
    .clk(clk_cpu),
    .AB(AB[1:0]),
    .WE(WE), 
    .CS(CS_resetvector),
    .CS_o(CS_resetvector_o),
    .DO(DI)
  );

  led_perif my_led_perif( 
    .clk(clk_cpu),
    .AB(AB[1:0]), 
    .WE(WE), 
    .CS(CS_led_perif),
    .CS_o(CS_led_perif_o), 
    .DI(DO), 
    .DO(DI), 
    .led(led)
  );

  uart_perif my_uart_perif( 
    .clk(clk_cpu), 
    .uart_clk(clk),
    .AB(AB[1:0]), 
    .WE(WE), 
    .CS(CS_uart_perif), 
    .CS_o(CS_uart_perif_o), 
    .DI(DO), 
    .DO(DI),
    .tx_pin(uartTx),
    .test_pin(clk_o)
  );


  assign CS_mem = ((AB & 16'hFE00) == 16'hAA00) ? 1 : 0;
  assign CS_resetvector = ((AB & 16'hFFFC) ==  16'hFFFC)  ? 1 : 0 ;
  assign CS_led_perif = (AB ==  16'h0010)  ? 1 : 0 ;
  assign CS_uart_perif = ((AB & 16'hFFFC) == 16'h0020)  ? 1 : 0 ;

  always @(posedge clk_cpu) begin
    CS_mem_o <= CS_mem & ~WE;
    CS_resetvector_o <= CS_resetvector & ~WE;
    CS_led_perif_o <= CS_led_perif & ~WE;
    CS_uart_perif_o <= CS_uart_perif & ~WE;
  end
  

  `ifndef TEST
  localparam CLKDIV = 1350000;
  `endif 

  `ifdef TEST
  localparam CLKDIV = 1;
  `endif 

  localparam reset_del = 2;
  reg [7:0] reset_cntr = 0;
  reg [23:0] counter = 0;


  // cpu clock divider
  always @(posedge clk) begin
    if (counter == CLKDIV) begin
      clk_cpu = clk_cpu ^ 1'b1;
      counter <= 0;
    end else begin
      counter <= counter + 24'b1;
    end 
  end

  // reset signal
  always @(posedge clk_cpu) begin
    if (reset) begin
      if (reset_cntr == reset_del) begin
        reset = 0;
      end
      reset_cntr <= reset_cntr + 8'b1;
    end
  end

endmodule