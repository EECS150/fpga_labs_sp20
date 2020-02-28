`timescale 1ns/1ns
`include "../../lib/EECS151.v"

module z1top_fifo_io (
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

    localparam FIFO_WIDTH = 4;
    localparam FIFO_LOGDEPTH = 3; // 8 entries

    wire [FIFO_WIDTH-1:0] fifo_enq_data, fifo_deq_data;
    wire fifo_enq_valid, fifo_enq_ready, fifo_deq_valid, fifo_deq_ready;
    fifo #(.WIDTH(FIFO_WIDTH), .LOGDEPTH (FIFO_LOGDEPTH)) FIFO (
        .clk(CLK_125MHZ_FPGA),
        .rst(1'b0),

        .enq_valid(fifo_enq_valid),  // input
        .enq_data(fifo_enq_data),    // input
        .enq_ready(fifo_enq_ready),  // output

        .deq_valid(fifo_deq_valid),  // output
        .deq_data(fifo_deq_data),    // output
        .deq_ready(fifo_deq_ready)); // input

    assign fifo_enq_valid = |(buttons_pressed);
    assign fifo_enq_data = (buttons_pressed[0] == 1) ? 4'b0001 :
                           (buttons_pressed[1] == 1) ? 4'b0010 :
                           (buttons_pressed[2] == 1) ? 4'b0011 :
                           (buttons_pressed[3] == 1) ? 4'b0100 : 0;

    wire [31:0] time_cnt_val, time_cnt_next;
    REGISTER_R #(.N(32)) time_cnt (.q(time_cnt_val), .d(time_cnt_next), .rst(time_cnt_rst), .clk(CLK_125MHZ_FPGA));
    assign time_cnt_next = time_cnt_val + 1;
    assign time_cnt_rst = (time_cnt_val == 125_000_000 / 2 - 1);

    // read from the FIFO after 0.5 sec and SWITCHES[0] is OFF
    assign fifo_deq_ready = (time_cnt_val == 125_000_000 / 2 - 1) && (SWITCHES[0] == 0);

    wire [3:0] led_status_val, led_status_next;
    wire led_status_ce;
    REGISTER_CE #(.N(4)) led_status (.q(led_status_val), .d(led_status_next), .ce(led_status_ce), .clk(CLK_125MHZ_FPGA));
    assign led_status_next = fifo_deq_data;
    assign led_status_ce = fifo_deq_valid && fifo_deq_ready;

    assign LEDS[3:0] = led_status_val;

endmodule
