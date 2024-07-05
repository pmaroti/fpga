module nco(input clk, input [15:0] fcw, output [15:0] m, output s, output [7:0] sine);
    
    reg [11:0] acc = 0;
    reg [7:0] phase = 0;
    wire [7:0] sss;

    sinlt i1 (phase, sss);

    always @(posedge clk) begin
        acc <= acc + fcw;
        phase <= acc[11:4];
    end

    assign m = acc;
    assign s = acc[11];
    assign sine = sss;

endmodule