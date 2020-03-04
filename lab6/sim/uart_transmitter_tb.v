`timescale 1ns/1ns

module uart_transmitter_tb();
    localparam CLOCK_FREQUENCY  = 125_000_000;
    localparam CLOCK_PERIOD     = 1_000_000_000 / CLOCK_FREQUENCY;
    localparam BAUD_RATE        = 115_200;
    localparam SYMBOL_EDGE_TIME = CLOCK_FREQUENCY / BAUD_RATE;

    reg clk, rst;
    initial clk = 0;
    always #(CLOCK_PERIOD / 2) clk = ~clk;
    
    reg [7:0] data_in;
    reg data_in_valid;
    wire data_in_ready;
    wire serial_out;

    uart_transmitter dut (
        .clk(clk),
        .rst(rst),

        .data_in(data_in),             // input
        .data_in_valid(data_in_valid), // input
        .data_in_ready(data_in_ready), // output
        .serial_out(serial_out)        // output
    );

    reg [10-1:0] tx_char;
    integer i;
    localparam CHAR1 = 8'h41;
    localparam CHAR2 = 8'h42;
    localparam CHAR3 = 8'h43;
    localparam CHAR4 = 8'h44;

    // This only tests sending a single character
    // You should add more test, such as sending multiple characters in a row
    initial begin
        #0;
        rst = 1;
        data_in = 8'h0;
        data_in_valid = 0;
        tx_char = 10'h0;

        // Hold reset for a while
        repeat (10) @(posedge clk);

        rst = 0;

        // Wait until uart_transmitter is ready to accept input data
        while (data_in_ready == 0) begin
            @(posedge clk);
        end

        // uart_transmitter fires the input data
        @(posedge clk); #1;
        data_in = CHAR1;
        data_in_valid = 1;

        @(posedge clk); #1;
        data_in_valid = 0;

        // Wait until serial_out is LOW (start of transaction)
        while (serial_out == 1) begin
            @(posedge clk);
        end

        for (i = 0; i < 10; i = i + 1) begin
            tx_char[i] = serial_out;
            #(SYMBOL_EDGE_TIME * CLOCK_PERIOD);
        end

        // Wait for some time
        repeat (10) @(posedge clk);

        $display("Got char: %h", tx_char[8:1]);
        if (tx_char[0] != 0)
            $display("Failed: Start bit is not 0!");
        else if (tx_char[9] != 1)
            $display("Failed: End bit is not 1!");
        else if (tx_char[8:1] != CHAR1)
            $display("Failed: Payload mismatches: Sent=%d Got=%d\n", CHAR1, tx_char);
        else if (serial_out != 1)
            $display("Failed: serial_out should stay HIGH after transmission!");
        else
            $display("Test passed!");

        #100;
        $finish();
    end

endmodule
