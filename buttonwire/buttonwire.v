module buttonwire
(
    output outbit,
    input btn1,
    input clk
);

/*

localparam WAIT_TIME = 27000;
reg ledCounter = 0;
reg [23:0] clockCounter = 0;

always @(posedge clk) begin
    clockCounter <= clockCounter + 1;
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 0;
        ledCounter <= ledCounter + 1;
    end
end

assign outbit = ~ledCounter;

*/
assign outbit = ~btn1;


endmodule