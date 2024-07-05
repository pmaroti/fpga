module test();
    reg clk = 0;
    reg [15:0] fcw = 10;
    wire [15:0] ppp;
    wire signal;
    wire [7:0] osin;

    nco u(clk, fcw, ppp, signal, osin);

    always
        #1  clk = ~clk;

    initial begin
        $display("Starting NCO");
        $monitor("Output Value %h", ppp);
        #1000 assign fcw = 30;
        #1000 $finish;

    end

    initial begin
        $dumpfile("nco.vcd");
        $dumpvars(0, test);
    end    

endmodule