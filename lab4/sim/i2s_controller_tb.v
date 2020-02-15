`timescale 1ns/1ns

module i2s_controller_tb();
    localparam CLK_FREQ = 125_000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;

    localparam MCLK_TO_LRCLK_RATIO = 512;
    localparam NUM_SAMPLE_BITS = 16;

    reg clock;
    initial clock = 0;
    always #(CLK_PERIOD / 2) clock <= ~clock;
    
    wire mclk;
    wire lrclk;
    wire sclk;

    i2s_controller dut (
        .clk(clock),
        .mclk(mclk),
        .lrclk(lrclk),
        .sclk(sclk)
    );

    // We must ensure that the ratios meet the spec
    // for the lab, we expect the master-to-left/right clock to be 512
    // and the serial-to-left/right clock to be 32
    integer m_start, m_end;
    integer lr_start, lr_end;
    integer s_start, s_end;
    integer m2lr, s2lr;

    initial begin
       #1000;

       @(posedge mclk); m_start = $time;
       @(posedge mclk); m_end = $time;
       #100;
       @(posedge lrclk); lr_start = $time;
       @(posedge lrclk); lr_end = $time;
       #100;
       @(posedge sclk); s_start = $time;
       @(posedge sclk); s_end = $time;

       #10;
       m2lr = (lr_end - lr_start) / (m_end - m_start);
       s2lr = (lr_end - lr_start) / (s_end - s_start);
       $display("m_start=%d, m_end=%d, lr_start=%d, lr_end=%d, s_start=%d, s_end=%d",
         m_start, m_end, lr_start, lr_end, s_start, s_end);
       $display("M2LR = %f (expected 512), LR2S = %f (expected 16 * 2)\n", m2lr, s2lr);
       $finish();
    end

endmodule
