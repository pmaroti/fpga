module test();
    reg d = 0;
    reg clk = 0;
    reg reset = 0;
    reg set = 0;

    wire q;

    ff3 my_ff(q,clk,d,reset,set);

    always
        #1  clk = ~clk;

    initial begin


        #4 {d,reset,set} = 3'b100;
        #4 {d,reset,set} = 3'b000;
        #4 {d,reset,set} = 3'b001;
        #4 {d,reset,set} = 3'b010;
        #4 {d,reset,set} = 3'b011;
        #4 $finish();

    end

    initial begin
        $dumpfile("ff3.vcd");
        $dumpvars(0,test);
    end    

endmodule