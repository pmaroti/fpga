
module uart_chip( clk, reset, AB, DO, DI, CS, WE, uartRx, uartTx);

    input  clk;             // system clock 
    input  reset;           // reset signal
    input  [7:0] AB;        // address bus
    output [7:0] DO;        // data out
    input  [7:0] DI;        // data in
    input  CS;              // chip select
    input  WE;              // write
    input  uartRx;
    output reg uartTx;

    reg [7:0]uart_do;      // internal data out bus
    reg oe_reg;            // output_enable_register

    localparam DELAY_FRAMES = 240; // 27,000,000 (27Mhz) / 115200 Baud rate
    localparam DELAYHALF_FRAME = 117;  // 0.5 bit length

    localparam IDLE =  3'd0,
               START = 3'd1,
               DATA =  3'd2,
               STOP =  3'd3;

    reg [7:0] rx_byte;      // bytes received
    reg [2:0] rx_status;    // rx status
    reg received;           // received status flag
    reg receive_set;        // set received status
    reg receive_read;       // clear received status
    reg o_receive_set;      // old value of
    reg o_receive_read;     // old value of
    reg [15:0] rx_counter;  // counter during receiving
    reg [2:0] bit_counter;  // bit counter


    // processor interface
    always @(posedge clk) begin
      oe_reg <= CS && !WE;    // in case of read operation we will provide data to the data bus

      if (CS) begin         // chip selected?
        if (!WE) begin      // read operation?
          if(AB[0] == 1'b0) begin // status register read (addr 0)
            uart_do <= {6'b0000_00, sending, received};  // uart status register 
            receive_read <= 1'b0;  // prepare for received status flag
            tx_set <= 1'b0;        // prepare for sending status flag
          end else begin           // received byte read
            uart_do <= rx_byte;    // set output data (addr 1)
            receive_read <= 1'b1;  // clear received status flag
          end
        end else begin      // write operation (addr 0/1)
          tx_byte <= DI;    // save byte to send
          tx_set <= 1'b1;   // set sending flag!
        end
      end 
    end

    assign DO = (oe_reg) ? uart_do : 8'bzzzz_zzzz;

  // UART status handling
  always @(posedge clk) begin
    if (reset) begin            // in case of reset
      received <= 1'b0;         // nothing is received
      sending <= 1'b0;          // nothing to send
      o_receive_set <= 1'b0;    // old value of
      o_receive_read <= 1'b0;   // old value of
      o_tx_sent <= 1'b0;        // old value of
      o_tx_set <= 1'b0;         // old value of
    end

    if (receive_set && !o_receive_set)    // in case of set 0->1
      received <= 1'b1;         // set the received status

    if (receive_read && !o_receive_read)  // in case of read 0->1
      received <= 1'b0;         // clear the received status

    if (tx_set && !o_tx_set)    // in case of set 0->1
      sending <= 1'b1;          // set the sending status
    
    if (tx_sent && !o_tx_sent)  // in case of sent 0->1
      sending <= 1'b0;          // clear the sending status

    o_receive_set <= receive_set;
    o_receive_read <= receive_read;
    o_tx_set <= tx_set;
    o_tx_sent <= tx_sent;
  end

  always @(posedge clk) begin
    if (reset) begin
      rx_status <= IDLE;      // reset rx status
    end

    case(rx_status)
      IDLE: begin
        receive_set <= 1'b0;        // clear received flag
        if (uartRx == 0) begin      // if startbit
          rx_status <= START;       // next status is START
          rx_counter <= 0;          // counter clear
        end
      end

      START: begin
        if (rx_counter < (DELAY_FRAMES+DELAYHALF_FRAME) ) begin
          rx_counter <= rx_counter + 1;
        end else begin
          rx_status <= DATA;
          rx_counter <= 0;
          bit_counter <= 0;
          rx_byte[0] <= (uartRx);
        end
      end

      DATA: begin
        if (rx_counter < DELAY_FRAMES) begin
          rx_counter <= rx_counter + 1;
        end else begin
          rx_byte[bit_counter+1] <= (uartRx);
          rx_counter <= 0;
          if (bit_counter == 7) begin
            rx_status <= STOP;
          end else begin
            bit_counter <= bit_counter + 1;
          end
        end
      end

      STOP: begin
        if (rx_counter < (DELAY_FRAMES+DELAYHALF_FRAME) ) begin
          rx_counter <= rx_counter + 1;
        end else begin
          rx_status <= IDLE;
          receive_set <= 1'b1;
        end
      end

      default: begin
        rx_status <= IDLE;
      end
    endcase
  end

  reg [7:0] tx_byte;
  reg [2:0] tx_status;
  reg sending;
  reg tx_set;
  reg tx_sent;
  reg o_tx_set;
  reg o_tx_sent;
  reg [15:0] tx_counter;
  reg [2:0] tx_bit_counter;

  always @(posedge clk) begin
    if (reset) begin
      tx_status <= IDLE;
      uartTx <= 1'b1;       // stop bit!!!!
    end

    case(tx_status)
      IDLE: begin
        if (sending) begin      // if bytes ready to send
          tx_status <= START;   // next state is STARTbit
          tx_counter <= 0;      // counter reset
          uartTx <= 1'b0;       // serial output line is low
          tx_sent <= 1'b0;      // prepare for sent status change
        end else begin
          uartTx <= 1'b1;       // if nothing to send keep output high
        end
      end

      START: begin
        if (tx_counter < DELAY_FRAMES ) begin   //if startbit time not exceeded
          tx_counter <= tx_counter + 1;     // wait...
        end else begin          // start sending data
          tx_status <= DATA;    // so next state is DATAsending
          tx_counter <= 0;      // counter clear
          tx_bit_counter <= 0;  // bit counter is 0
          uartTx <= tx_byte[0]; // the output line according to the bit0 of the sending byte
        end
      end

      DATA: begin
        if (tx_counter < DELAY_FRAMES) begin  // if bittime is not exceeded
          tx_counter <= tx_counter + 1;       // wait...
        end else begin                  // bittime exceeded
          tx_counter <= 0;              // counter reset
          if (tx_bit_counter == 7) begin   // it was the last bit?
            tx_status <= STOP;          // if yes then we should send a STOP bit
            uartTx <= 1'b1;             // with output line HIGH
            //tx_sent <= 1'b1;        // and clear the sending flag            
          end else begin                           // otherwise
            uartTx <= tx_byte[tx_bit_counter+1];   // we should send the next bit
            tx_bit_counter <= tx_bit_counter + 1;  // and increment bit counter for the transmission
          end
        end
      end

      STOP: begin
        tx_sent <= 1'b1;
        if (tx_counter < (DELAY_FRAMES) ) begin   // if stopbit time is not exceeded
          tx_counter <= tx_counter + 1;           // wait...
        end else begin            // otherwise 
          tx_status <= IDLE;      // sending is complete
        end
      end

      default: begin
        tx_status <= IDLE;
        uartTx <= 1'b1;
      end
    endcase
  end

endmodule	