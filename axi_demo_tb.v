`timescale 1ns/1ns

module axi_demo_tb();

reg clk, reset;
wire done;
wire error;

localparam NUM_OF_RUNNING_CLOCK_CYCLES = 300;

axi_demo axi (.clk(clk), .reset(reset), .done(done), .error(error));

initial begin

    $dumpfile("axi_demo_tb.vcd");
    $dumpvars(0, axi_demo_tb);

    clk = 0;
    reset = 0;
    
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    reset = 1;
    
    @(posedge clk);
    @(posedge clk);
    
    reset = 0;
    
    repeat(NUM_OF_RUNNING_CLOCK_CYCLES) @(posedge clk);  
    
    $finish;
end

localparam clk_period = 5;

always @(*) #clk_period clk <= !clk;
    
endmodule
