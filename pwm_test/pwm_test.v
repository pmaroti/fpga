module pwm_test
(
    output wire outbit,
    input wire clk
);

/*
Gowin_rPLL main_pll(
    .clkout(clko), //output clkout
    .clkin(clk) //input clkin
);
*/

localparam PWM_INIT = 64;
reg [7:0]pwm_val = PWM_INIT;
reg ooo = 0;
reg [7:0] pwmCounter = 0;

always @(posedge clk) begin
    pwmCounter <= pwmCounter + 8'b1;
    if ( (pwmCounter == 0) && (pwm_val != 0))  begin
        ooo <= 1;
    end
    if ( pwmCounter == pwm_val) begin
        ooo <= 0;
    end
end

assign outbit = ~ooo;

endmodule