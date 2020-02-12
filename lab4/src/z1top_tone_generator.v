`timescale 1ns/1ns
`include "../../lib/EECS151.v"

module z1top_tone_generator (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,

    output PMOD_OUT_PIN1,
    output PMOD_OUT_PIN2,
    output PMOD_OUT_PIN3,
    output PMOD_OUT_PIN4
);
    assign LEDS[5:4] = 2'b11;

    // Button parser
    // Sample the button signal every 500us
    localparam integer B_SAMPLE_CNT_MAX = 0.0005 * 125_000_000;
    // The button is considered 'pressed' after 100ms of continuous pressing
    localparam integer B_PULSE_CNT_MAX = 0.100 / 0.0005;

    wire [3:0] buttons_pressed;
    button_parser #(
        .WIDTH(4),
        .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
        .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
    ) bp (
        .clk(CLK_125MHZ_FPGA),
        .in(BUTTONS),
        .out(buttons_pressed)
    );

    wire mclk, lrclk, sclk, sdout;

    assign PMOD_OUT_PIN1 = mclk;
    assign PMOD_OUT_PIN2 = lrclk;
    assign PMOD_OUT_PIN3 = sclk;
    assign PMOD_OUT_PIN4 = sdout;

    i2s_controller i2s_controller (
        .clk(CLK_125MHZ_FPGA),
        .mclk(mclk),
        .lrclk(lrclk),
        .sclk(sclk)
    );

    localparam NUM_SAMPLE_BITS = 16;

    wire [NUM_SAMPLE_BITS-1:0] i2s_sample_data;
    wire i2s_sample_bit;
    wire i2s_sample_sent;
    i2s_bit_serial i2s_bit_serial (
        .serial_clk(sclk),
        .i2s_sample_sent(i2s_sample_sent),
        .i2s_sample_data(i2s_sample_data),
        .i2s_sample_bit(i2s_sample_bit)
    );

    // 440Hz-tone
    // If we make the memory depth to be a power-of-two value,
    // Vivado synthesis will run faster
    // It is a waste of memory unfortunately, but let's not worry about it now
    localparam TONE_ADDR_WIDTH = 16;
    localparam TONE_DATA_WIDTH = NUM_SAMPLE_BITS;
    localparam TONE_NUM_SAMPLES = 44100;
    localparam TONE_MEM_DEPTH = 65536;//44100;

    wire [TONE_ADDR_WIDTH-1:0] tone_440_mem_addr;
    wire [TONE_DATA_WIDTH-1:0] tone_440_mem_rdata;
    ASYNC_ROM #(
        .AWIDTH(TONE_ADDR_WIDTH),
        .DWIDTH(TONE_DATA_WIDTH),
        .DEPTH(TONE_MEM_DEPTH),
        .MEM_INIT_BIN_FILE("tone_440_data_bin.mif")
    ) tone_440_memory (
        .q(tone_440_mem_rdata), .addr(tone_440_mem_addr));

    // TODO: Your code to interface with the I2S protocol

endmodule
