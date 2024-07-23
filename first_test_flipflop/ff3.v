module ff3(q,clk,d,reset,set);
    output q;
    reg q;
    input clk, d, reset, set;
    
    /*
    always @(posedge clk)
        q <= d;

    initial begin
        q <= 0;
    end
    
    always @(reset or set)
        case( {reset,set} )
            2'b00: deassign q; 
            2'b10: assign q=0;
            2'b01: assign q=1;
            //default: assign q=1'bx;
            default: assign q=1'b0;
        endcase
    */

    always @(posedge clk or posedge reset or posedge set)
        if(reset)
            q <= 0;
        else
            if(set)
                q <= 1;
            else
                q <= d;

endmodule