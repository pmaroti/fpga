
module uart_chip( clk, reset, AB, DO, DI, CS, WE, uartRx);

    input  clk;              // CPU clock 
    input  reset;            // reset signal
    input  [7:0] AB;   // address bus
    output [7:0] DO;        // data out, write bus
    input  [7:0] DI;        // data in
    input  CS;              // chip select
    input  WE;              // write?
    input  uartRx;

    reg [7:0]uart_do;				// internal ram/rom data out bus
    reg oe_reg; 	

	localparam DELAY_FRAMES = 235; // 27,000,000 (27Mhz) / 115200 Baud rate
	localparam DELAYHALF_FRAME = 117;  // 0.5 bit length

	localparam IDLE =  3'd0,
               START = 3'd1,
               DATA =  3'd2,
               STOP =  3'd3;

	reg [7:0] rx_byte;
	reg [2:0] rx_status;
	reg received;
	reg receive_set;
	reg receive_read;
	
	reg o_receive_set;
	reg o_receive_read;

	reg [15:0] rx_counter;
	reg [2:0] bit_counter;


    always @(posedge clk) begin
		
		oe_reg <= CS && !WE;

        if (CS) begin
            if (!WE) begin
                if(AB[0] == 1'b0) begin
                    uart_do <= {7'b0000_000, received};
					receive_read <= 1'b0;
                end else begin
                    uart_do <= rx_byte;
					receive_read <= 1'b1;
                end
			end
		end 
    end

    assign DO = (oe_reg) ? uart_do : 8'bzzzz_zzzz;

	always @(posedge clk) begin
		if (reset) begin
			received <= 1'b0;
			o_receive_set <= 1'b0;
			o_receive_read <= 1'b0;
		end

		if (receive_set && !o_receive_set)
			received <= 1'b1;

		if (receive_read && !o_receive_read)
			received <= 1'b0;

		o_receive_set <= receive_set;
		o_receive_read <= receive_read;
	end

	always @(posedge clk) begin
		if (reset) begin
			rx_status <= IDLE;
		end

		case(rx_status)
			IDLE: begin
				receive_set <= 1'b0;
				if (uartRx == 0) begin
					rx_status <= START;
					rx_counter <= 0;
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
endmodule	