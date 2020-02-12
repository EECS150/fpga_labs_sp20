`include "../../lib/EECS151.v"

module i2s_controller #(
    parameter LRCK_FREQ_HZ = 44_100,
    parameter MCLK_TO_LRCK_RATIO = 512,
    parameter NUM_DATA_BITS = 16
) (
    input clk, // Source clock, from which others are derived

    // I2S control signals
    output mclk,  // Master clock
    output lrck, // Left-right clock, which determines which channel each audio frame is sent to.
    output sclk   // Serial clock (or bit clock), for transmitting each bit of a audio frame
);

    // This should be 125 MHz / 44.1 KHz ~ 2834.
    // However, 3072 does seem to work and it also ensures the master to left-right
    // clock ratio to be an integer
    localparam LRCK_CYCLES       = 3072; 
    localparam LRCK_HALF_CYCLES  = LRCK_CYCLES / 2;

    localparam MCLK_CYCLES       = LRCK_CYCLES / MCLK_TO_LRCK_RATIO;
    localparam MCLK_HALF_CYCLES  = MCLK_CYCLES / 2;

    localparam SCLK_CYCLES       = LRCK_HALF_CYCLES / NUM_DATA_BITS
    localparam SCLK_HALF_CYCLES  = SCLK_CYCLES / 2;

    // TODO: Fill in the remaining logic to implement I2S controller
    // Some initial code has been provided to you as a hint
    // Please feel free to change them however you like

    wire [31:0] mclk_cnt_val, mclk_cnt_next;
    wire mclk_cnt_rst;
    REGISTER_R #(32) mclk_cnt (.q(mclk_cnt_val), .d(mclk_cnt_next), .clk(clk), .rst(mclk_cnt_rst));

    wire [31:0] lrck_cnt_val, lrck_cnt_next;
    wire lrck_cnt_rst;
    REGISTER_R #(32) lrck_cnt (.q(lrck_cnt_val), .d(lrck_cnt_next), .clk(clk), .rst(lrck_cnt_rst));

    wire [31:0] sclk_cnt_val, sclk_cnt_next;
    wire sclk_cnt_rst;
    REGISTER_R #(32) sclk_cnt (.q(sclk_cnt_val), .d(sclk_cnt_next), .clk(clk), .rst(sclk_cnt_rst));

    // 1: Generate MCLK from clk. MCLK's frequency must be an integer multiple
    // of the sample rate, and hence LRCK rate, as defined in the PMOD I2S reference
    // manual and the Cirrus Logic CS4344 data sheet.

    wire mclk_gen_val, mclk_gen_next;
    wire mclk_gen_ce, mclk_gen_rst;
    REGISTER_CE #(.N(1)) master_clk_gen (.q(mclk_gen_val), .d(mclk_gen_next), .ce(mclk_gen_ce), .clk(clk));


    // 2: Generate the LRCK, the left-right clock.

    wire lrck_gen_val, lrck_gen_next;
    wire lrck_gen_ce, lrck_gen_rst;
    REGISTER_CE #(.N(1)) lrck_gen (.q(lrck_gen_val), .d(lrck_gen_next), .ce(lrck_gen_ce), .clk(clk));


    // 3. Generate the bit clock, or serial clock. It clocks transmitted bits for a 
    // whole sample on each half-cycle of the lr_clock. The frequency of this clock
    // relative to the lr_clock determines how wide our samples can be.

    wire sclk_gen_val, sclk_gen_next;
    wire sclk_gen_ce, sclk_gen_rst;
    REGISTER_CE #(.N(1)) sclk_gen (.q(sclk_gen_val), .d(sclk_gen_next), .ce(sclk_gen_ce), .clk(clk));


endmodule
