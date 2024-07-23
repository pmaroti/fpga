module posedge_check(
    input wire clk,
    input wire signal,
    output posedge_detected
);
    reg signal_d; 
    reg posedge_detected=0;

    always @(posedge clk) begin
        if (signal && !signal_d) begin
            posedge_detected <= 1'b1;
        end else begin
            posedge_detected <= 1'b0;
        end
        signal_d <= signal; 
    end
endmodule