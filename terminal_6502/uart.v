module uart
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115200 Baud rate
)
(
    input clk,
    input CS, 
    input [2:0] addr,
    input [7:0] DI,
    output [7:0] DO,
    input WE
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);


reg [3:0] txState = 0;
reg [7:0] dataOut = 0;
reg [2:0] txBitNumber = 0;

reg [7:0] uart_status = 0;


localparam UART_OK = 0;
localparam TX_ERROR = 1;
localparam TX_ERROR = 1;



always @(posedge clk) begin
    // read operations
    if (~WE) begin
        // fetch status
        if (addr == 2'b00) begin
            DO <= uart_status;
        end
    end

    // write operation
    if (WE) begin
        // byte to send
        if ( (txState == TX_STATE_IDLE) and (addr == 2'b01)) begin
            dataOut <= DI;
            txState <= TX_STATE_START_BIT;
            uart_status <= UART_OK;
        end else begin
            uart_status <= TX_ERROR;
        end

        if (addr == 2b'00) begin

        end
    end
end






reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [7:0] dataIn = 0;
reg [2:0] rxBitNumber = 0;
reg byteReady = 0;
reg send_ready = 0;

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;
localparam RX_STATE_WAIT_FOR_ACK = 6;


always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: begin
            rxCounter <= 1;
            dataIn <= {uart_rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_WAIT_FOR_ACK;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end

        RX_STATE_WAIT_FOR_ACK: begin
            if (receive_ack != 0 ) begin
                rxState <= RX_STATE_IDLE;
                byteReady <= 0;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (byteReady) begin
        char_received <= dataIn;
        receive_ready <= 1;
    end
end

reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [3:0] txByteCounter = 0;

assign uart_tx = txPinRegister;

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;
localparam TX_STATE_DEBOUNCE = 4;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (btn1 == 0) begin
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
            else begin
                txPinRegister <= 1;
            end
        end 
        TX_STATE_START_BIT: begin
            txPinRegister <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                dataOut <= testMemory[txByteCounter];
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            txPinRegister <= dataOut[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            txPinRegister <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == MEMORY_LENGTH - 1) begin
                    txState <= TX_STATE_DEBOUNCE;
                end else begin
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_DEBOUNCE: begin
            if (txCounter == 23'b111111111111111111) begin
                if (btn1 == 1) 
                    txState <= TX_STATE_IDLE;
            end else
                txCounter <= txCounter + 1;
        end
    endcase
end
endmodule