`timescale 1ns/1ns
`include "../../lib/EECS151.v"

module z1top_sum_memories (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS
);
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

    wire s_reset, s_done, a_reset, a_done;
    wire [31:0] s_sum, a_sum;
    wire [31:0] s_size, a_size;

    assign s_size = 1024;
    assign a_size = 1024;


    // Toggle the sum circuits
    wire s_reset_reg_val, s_reset_reg_next, s_reset_reg_ce;
    wire a_reset_reg_val, a_reset_reg_next, a_reset_reg_ce;
    REGISTER_CE #(.N(1)) s_reset_reg(.q(s_reset_reg_val), .d(s_reset_reg_next), .ce(s_reset_reg_ce), .clk(CLK_125MHZ_FPGA));
    REGISTER_CE #(.N(1)) a_reset_reg(.q(a_reset_reg_val), .d(a_reset_reg_next), .ce(a_reset_reg_ce), .clk(CLK_125MHZ_FPGA));
    assign s_reset_reg_next = ~s_reset_reg_val;
    assign a_reset_reg_next = ~a_reset_reg_val;
    assign s_reset_reg_ce = buttons_pressed[0];
    assign a_reset_reg_ce = buttons_pressed[1];
    assign s_reset = s_reset_reg_val;
    assign a_reset = a_reset_reg_val;

    localparam AWIDTH = 10;
    localparam DWIDTH = 32;
    localparam DEPTH = 1024;

    sum_sync_mem #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE("sync_mem_init_hex.mif")
    ) SMEM_SUM (
        .clk(CLK_125MHZ_FPGA),
        .reset(s_reset),
        .done(s_done),
        .size(s_size),
        .sum(s_sum)
    );

    sum_async_mem #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE("async_mem_init_hex.mif")
    ) AMEM_SUM (
        .clk(CLK_125MHZ_FPGA),
        .reset(a_reset),
        .done(a_done),
        .size(a_size),
        .sum(a_sum)
    );

    // Checksums
    assign LEDS[5] = (s_sum == 541587138) && (s_done == 1);
    assign LEDS[4] = (a_sum == 514007903) && (a_done == 1);
    assign LEDS[3:0] = 4'hFF;
endmodule
