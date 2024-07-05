module pll_test
(
    output wire outbit,
    input wire clk
);


Gowin_rPLL main_pll(
    .clkout(clko), //output clkout
    .clkin(clk) //input clkin
);


localparam WAIT_TIME = 20;
reg ooo = 0;
reg [23:0] clockCounter = 0;

always @(posedge clko) begin
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 0;
        ooo <= ooo ^ 1'b1;
    end 
    else begin
        clockCounter <= clockCounter + 24'b1;
    end
end


assign outbit = ~ooo;


endmodule