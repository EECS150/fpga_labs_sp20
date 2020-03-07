`timescale 1ns/1ns

module uart_receiver_tb();
    localparam CLOCK_FREQUENCY  = 125_000_000;
    localparam CLOCK_PERIOD     = 1_000_000_000 / CLOCK_FREQUENCY;
    localparam BAUD_RATE        = 115_200;
    localparam BAUD_PERIOD      = 1_000_000_000 / BAUD_RATE; // 8680.55 ns

    localparam CHAR0 = 8'h61; // ~ 'a'
    localparam NUM_CHARS = 10;

    reg clk, rst;
    initial clk = 0;
    always #(CLOCK_PERIOD / 2) clk = ~clk;
    
    wire [7:0] data_out;
    wire data_out_valid;
    reg data_out_ready;
    reg serial_in;

    uart_receiver #(
        .CLOCK_FREQ(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),

        .data_out(data_out),             // output
        .data_out_valid(data_out_valid), // output
        .data_out_ready(data_out_ready), // input
        .serial_in(serial_in)            // input
    );

    reg data_out_fired;
    integer i, c;

    // this holds characters sent by the host via serial line
    reg [7:0] chars_from_host [NUM_CHARS-1:0];
    // this holds characters received from the host and be dequeued to data_out via R/V
    reg [7:0] chars_to_data_out [NUM_CHARS-1:0];

    // initialize test vectors
    initial begin
        #0
        for (c = 0; c < NUM_CHARS; c = c + 1) begin
           chars_from_host[c] = CHAR0 + c;
        end
    end

    reg [31:0] cnt;

    always @(posedge clk) begin
        // data considered "dequeued" ("fired") when both valid and ready are
        // HIGH
        if (data_out_valid & data_out_ready) begin
            chars_to_data_out[cnt] <= data_out;
            data_out_fired <= 1'b1;
            cnt <= cnt + 1;
            $display("[time %t] [data_out] Got char: 8'h%h", $time, data_out);
        end

        // data_out_valid should be LOW in the next rising edge
        // after "fired"
        if (data_out_fired) begin
            if (data_out_valid == 1'b1) begin
                $display("[time %t] Failed: data_out_valid should go LOW after firing data_out\n", $time);
                $finish();
            end
            data_out_fired <= 1'b0;
        end
    end

    integer num_mismatches = 0;

    initial begin
        #0;
        cnt = 0;
        rst = 1;
        data_out_ready = 0;
        data_out_fired = 0;
        serial_in = 1;

        // Hold reset for a while
        repeat (10) @(posedge clk);

        rst = 0;

        if (data_out_valid == 1'b1) begin
            $display("[time %t] Failed: data_out_valid should not be HIGH initially", $time);
            $finish();
        end

        // the testbench is ready to accept uart_receiver output data
        data_out_ready = 1;

        // Delay for some time
        repeat (100) @(posedge clk);

        // Send NUM_CHARS characters in a row non-stop
        for (c = 0; c < NUM_CHARS; c = c + 1) begin
            // This emulates how serial line sends data
            // Start bit
            serial_in = 0;
            #(BAUD_PERIOD);
            // Data bits (payload)
            for (i = 0; i < 8; i = i + 1) begin
                serial_in = chars_from_host[c][i];
                #(BAUD_PERIOD);
            end
            // Stop bit
            serial_in = 1;
            #(BAUD_PERIOD);
            $display("[time %t] [serial_in] Sent char 8'h%h", $time, chars_from_host[c]);
        end

        // Delay for some time
        repeat (3) @(posedge clk);

        // Check results
        for (c = 0; c < NUM_CHARS; c = c + 1) begin
            if (chars_to_data_out[c] !== chars_from_host[c]) begin
                $display("Mismatches at char %d: char_from_host=%h, char_to_data_out=%h",
                         c, chars_from_host[c], chars_to_data_out[c]);
                num_mismatches = num_mismatches + 1;
            end
        end

        if (num_mismatches > 0)
            $display("Test failed");
        else
            $display("Test passed!");

        $finish();
    end

    initial begin
        #(BAUD_PERIOD * 10 * (NUM_CHARS + 1));
        $display("TIMEOUT");
        $finish();
    end
endmodule
