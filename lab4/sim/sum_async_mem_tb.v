`timescale 1ns/1ns

module sum_async_mem_tb();
    localparam AWIDTH = 10;
    localparam DWIDTH = 32;
    localparam DEPTH = 1024;

    reg clk;
    initial clk = 0;
    always #(4) clk <= ~clk;
    
    reg reset;
    reg [31:0] size;
    wire [DWIDTH-1:0] sum;
    wire done;

    sum_async_mem #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE("async_mem_init_hex.mif")
    ) dut (
        .clk(clk),
        .reset(reset),
        .done(done),
        .size(size),
        .sum(sum)
    );

    // "Software" version
    reg [31:0] test_vector [DEPTH-1:0];
    integer sw_sum = 0;
    integer i;
    initial begin
        #0;
        $readmemh("async_mem_init_hex.mif", test_vector);
        #1; // advance one tick to make sure  sw_sum get updated
        for (i = 0; i < size; i = i + 1) begin
            sw_sum = sw_sum + test_vector[i];
        end
    end

    reg [31:0] cycle_cnt;

    always @(posedge clk) begin
        cycle_cnt <= cycle_cnt + 1;

        if (done) begin
            $display("At time %d, sum = %d, sw_sum = %d, done = %d, number of cycles = %d", $time, sum, sw_sum, done, cycle_cnt);
            if (sum == sw_sum)
                $display("TEST PASSED!");
            else
                $display("TEST FAILED!");
            $finish();
        end
    end

    initial begin
        #0;
        reset = 0;
        size = 1024;
        cycle_cnt = 0;

        repeat (10) @(posedge clk);
        reset = 1;
        @(posedge clk);
        reset = 0;

        repeat (5 * DEPTH) @(posedge clk);
        $display("Timeout");
        $finish();
    end

endmodule
