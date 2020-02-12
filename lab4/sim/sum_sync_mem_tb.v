`timescale 1ns/1ns

module sum_sync_mem_tb();
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

    sum_sync_mem #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE("sync_mem_init_hex.mif")
    ) dut (
        .clk(clk),
        .reset(reset),
        .done(done),
        .size(size),
        .sum(sum)
    );

    reg [31:0] cycle_cnt;

    always @(posedge clk) begin
        cycle_cnt <= cycle_cnt + 1;

        if (done) begin
            $display("At time %d, sum = %d, done = %d, number of cycles = %d", $time, sum, done, cycle_cnt);
            if (sum == 541587138)
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
