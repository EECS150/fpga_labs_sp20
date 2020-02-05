`timescale 1ns/1ns

module counter_tb();
    parameter N = 6;
    parameter RATE_HZ = 25_000_000;   // 25 MHz
    parameter CLK_FREQ = 125_000_000; // 125 MHz
    parameter CLK_PERIOD = 1_000_000_000 / CLK_FREQ; // 8ns

    reg clock;
    initial clock = 0;
    always #(CLK_PERIOD / 2) clock <= ~clock;
    
    reg rst_counter;
    reg [N-1:0] rst_counter_val;
    wire [N-1:0] counter_output;

    counter #(N, RATE_HZ) dut (
        .clk(clock),
        .rst_counter(rst_counter),
        .rst_counter_val(rst_counter_val),
        .counter_output(counter_output)
    );

    initial begin
        #0;
        rst_counter <= 0;
        rst_counter_val <= 0;
        #200;
        rst_counter <= 1;
        rst_counter_val <= 13;
        #220; 
        rst_counter <= 0; // Hold the reset_counter signal for 20ns
        #1000;
        $display("Time %d\n", $time);

        $finish();
    end

endmodule
