`timescale 1ns/1ns

module uart_receiver_tb();
    localparam CLOCK_FREQUENCY  = 125_000_000;
    localparam CLOCK_PERIOD     = 1_000_000_000 / CLOCK_FREQUENCY;
    localparam BAUD_RATE        = 115_200;
    localparam OFFSET           = 10;
    localparam SYMBOL_EDGE_TIME = CLOCK_FREQUENCY / BAUD_RATE - OFFSET;

    reg clk, rst;
    initial clk = 0;
    always #(CLOCK_PERIOD / 2) clk = ~clk;
    
    wire [7:0] data_out;
    wire data_out_valid;
    reg data_out_ready;
    reg serial_in;

    uart_receiver dut (
        .clk(clk),
        .rst(rst),

        .data_out(data_out),             // output
        .data_out_valid(data_out_valid), // output
        .data_out_ready(data_out_ready), // input
        .serial_in(serial_in)            // input
    );

    reg [7:0] rx_char;
    reg rx_fired;

    integer i;
    localparam CHAR1 = 8'h41;
    localparam CHAR2 = 8'h42;
    localparam CHAR3 = 8'h43;
    localparam CHAR4 = 8'h44;

    always @(posedge clk) begin
        if (data_out_valid & data_out_ready) begin
            rx_char <= data_out;
            rx_fired <= 1'b1;
        end
    end

    // This only tests receiving a single character
    // You should add more test, such as receiving multiple characters in a row
    initial begin
        #0;
        rst = 1;
        data_out_ready = 0;
        rx_char = CHAR1;
        rx_fired = 0;
        serial_in = 1;

        // Hold reset for a while
        repeat (10) @(posedge clk);

        rst = 0;

        // the testbench is ready to accept uart_receiver output data
        data_out_ready = 1;

        // Pull serial_in LOW to start the transaction (START bit)
        serial_in = 0;
        #(SYMBOL_EDGE_TIME * CLOCK_PERIOD);

        for (i = 0; i < 8; i = i + 1) begin
            serial_in = rx_char[i];
            #(SYMBOL_EDGE_TIME * CLOCK_PERIOD);
        end

        // IDLE bit
        serial_in = 1;
        #(SYMBOL_EDGE_TIME * CLOCK_PERIOD);

        // Waiting for uart_receiver to fire output data
        while (rx_fired == 0) begin
            @(posedge clk);
        end

        $display("Got char: %h", rx_char);
        if (data_out != CHAR1)
            $display("Failed: Payload mismatches: Sent=%d Got=%d\n", CHAR1, rx_char);
        else
            $display("Test passed!");

        #100;
        $finish();
    end

    initial begin
        #(SYMBOL_EDGE_TIME * CLOCK_PERIOD * 12);
        $display("TIMEOUT");
        $finish();
    end
endmodule
