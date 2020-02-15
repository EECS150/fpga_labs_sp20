`timescale 1ns/1ns

module i2s_bit_serial_tb();
    localparam CLK_PERIOD = 10; // 10ns -- doesn't really matter
    localparam NUM_SAMPLE_BITS = 16;
 
    reg clock;
    initial clock = 0;
    always #(CLK_PERIOD / 2) clock <= ~clock;
    
    reg [NUM_SAMPLE_BITS-1:0] i2s_sample_data;
    wire i2s_sample_sent;
    wire i2s_sample_bit;


    i2s_bit_serial dut (
        .serial_clk(clock),
        .i2s_sample_data(i2s_sample_data), // input
        .i2s_sample_sent(i2s_sample_sent), // output
        .i2s_sample_bit(i2s_sample_bit)    // output
    );

    reg [NUM_SAMPLE_BITS-1:0] bits;
    initial begin
       #0;
       // we want to serialize this data, from MSB to LSB
       i2s_sample_data = 16'hABCD;
       bits = 0;

       repeat (16) begin
           @(posedge clock); #1;
           bits = (bits << 1) | i2s_sample_bit;
           $display("At time %d, i2s_sample_bit = %d, i2s_sample_sent = %d",
             $time, i2s_sample_bit, i2s_sample_sent);
       end

       @(posedge clock);
       $display("Received %x", bits);
       if (bits == i2s_sample_data)
           $display("TEST PASSED");
       else
           $display("TEST FAILED");

       $finish();
    end

endmodule
