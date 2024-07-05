module test();
    reg a = 0;
    reg b = 0;
    wire c;

    mygate u(a, b, c);

    initial begin
        $display("Starting MYGATE");
        $monitor("Output Value %b", c);

        #1 {a, b} = 2'b01;
        #1 {a, b} = 2'b10;
        #1 {a, b} = 2'b11;
        #1;

    end

    initial begin
        $dumpfile("gate.vcd");
        $dumpvars(0,test);
    end    

endmodule