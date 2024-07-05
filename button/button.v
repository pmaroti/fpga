module button
(
    input clk,
    input btn1,
    output [5:0] led
);

reg [23:0] clockCounter = 0;
reg [5:0] ledCounter = 0;

reg state = 0;
localparam IDLE = 0;
localparam PUSHED = 1;
localparam wtime = 2_700_000;

always @(posedge clk) begin
    if (state == IDLE) begin
        if (btn1 == 1'b0) begin
            ledCounter <= ledCounter + 1;
            state <= PUSHED;
            clockCounter <= 0;
        end
    end
    if (state == PUSHED) begin
        if (clockCounter > wtime) begin
            if (btn1 == 1'b1) begin
                state <= IDLE;
            end
        end
        clockCounter <= clockCounter+1;
    end
end

assign led = ~ledCounter;
endmodule