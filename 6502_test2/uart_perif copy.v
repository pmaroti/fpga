module uart_perif(
  input clk,
  input uart_clk, 
  input [1:0] AB,
  input WE,
  input CS,
  input CS_o, 
  input [7:0] DI,
  output wire [7:0] DO,
  output wire tx_pin
);

  localparam DELAY_FRAMES = 234; // 27,000,000 (27Mhz) / 115200 Baud rate

  localparam IDLE = 3'd0,
             START = 3'd1,
             DATA = 3'd2,
             STOP = 3'd3;

  reg [2:0] uart_status = IDLE;
  reg [7:0] uart_output = 0;

  reg [7:0] uart_tx_byte;
  reg tx_pinReg = 1;
  reg to_send=0;
  reg busy = 0;
  reg [24:0] txCounter=0;
  reg [2:0] txBitNumber = 0;


  assign DO = (CS_o) ? uart_output : 8'bz;
  assign tx_pin = tx_pinReg;

  always @(negedge clk) begin
    if (CS) begin
      if (WE && ~busy) begin
        uart_tx_byte <= DI;
        to_send <= 1;
      end
      if (busy) begin
        to_send <= 0;
      end
    end
  end

  always @(posedge uart_clk) begin
    case (uart_status)
      IDLE: begin
        if (to_send) begin
            uart_status <= START;
            txCounter <= 0;
            busy <= 1;
        end
      end

      START: begin
          tx_pinReg <= 0; // Start bit
          if (txCounter < DELAY_FRAMES - 1) begin
              txCounter <= txCounter + 1;
          end else begin
              txCounter <= 0;
              uart_status <= DATA;
              txBitNumber <= 0;
          end
      end

      DATA: begin
          tx_pinReg <= uart_tx_byte[txBitNumber];
          if (txCounter < DELAY_FRAMES - 1) begin
              txCounter <= txCounter + 1;
          end else begin
              txCounter <= 0;
              if (txBitNumber < 7) begin
                  txBitNumber <= txBitNumber + 1;
              end else begin
                  uart_status <= STOP;
              end
          end
      end

      STOP: begin
          tx_pinReg <= 1; // Stop bit
          if (txCounter < DELAY_FRAMES - 1) begin
              txCounter <= txCounter + 1;
          end else begin
              txCounter <= 0;
              uart_status <= IDLE;
              busy <= 0;
          end
      end

      default: uart_status <= IDLE;
  endcase
  end

endmodule


