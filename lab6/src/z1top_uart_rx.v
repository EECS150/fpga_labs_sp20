`timescale 1ns/1ns

// You should not need to change this file
module z1top_uart_rx (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,

    output pixel_clk,

    // video signals
    output [23:0] video_out_pData,
    output video_out_pHSync,
    output video_out_pVSync,
    output video_out_pVDE,

     (* mark_debug = "true" *) input FPGA_SERIAL_RX
);

    localparam FIFO_WIDTH = 8;
    localparam FIFO_LOGDEPTH = 10;

    wire clk_in1, clk_out1;
    assign pixel_clk = clk_out1;
    assign clk_in1 = CLK_125MHZ_FPGA;

    localparam PIXEL_CLK_PERIOD = 25;
    localparam PIXEL_CLK_FREQ = 1_000_000_000 / PIXEL_CLK_PERIOD;
    // Clocking wizard IP from Vivado (wrapper of the PLLE module)
    // Generate PIXEL_CLK_FREQ clock from 125 MHz clock
    // PLL FREQ = (CLKFBOUT_MULT_F * 1000 / (CLKINx_PERIOD * DIVCLK_DIVIDE) must be within (800.000 MHz - 1600.000 MHz)
    // CLKOUTx_PERIOD = CLKINx_PERIOD x DIVCLK_DIVIDE x CLKOUT0_DIVIDE / CLKFBOUT_MULT_F
    clk_wiz #(
        .CLKIN1_PERIOD(8),
        .CLKFBOUT_MULT_F(8),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE(PIXEL_CLK_PERIOD)
    ) clk_wiz (
        .clk_out1(clk_out1), // output
        .reset(1'b0),        // input
        .locked(),           // output, unused
        .clk_in1(clk_in1)    // input
    );

    // Button parser
    // Sample the button signal every 500us
    localparam integer B_SAMPLE_CNT_MAX = 0.0005 * PIXEL_CLK_FREQ;
    // The button is considered 'pressed' after 100ms of continuous pressing
    localparam integer B_PULSE_CNT_MAX = 0.100 / 0.0005;

    wire [3:0] buttons_pressed;
    button_parser #(
        .WIDTH(4),
        .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
        .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
    ) bp (
        .clk(pixel_clk),
        .in(BUTTONS),
        .out(buttons_pressed)
    );

    wire reset = (buttons_pressed[0] & SWITCHES[1]);

    wire gray_select  = buttons_pressed[3];
    wire red_select   = buttons_pressed[2];
    wire green_select = buttons_pressed[1];
    wire blue_select  = buttons_pressed[0];

    wire [3:0] color_switch_val;

    REGISTER_R_CE #(.N(4)) color_switch_r (
        .q(color_switch_val),
        .d({gray_select, red_select, green_select, blue_select}),
        .ce(gray_select | red_select | green_select | blue_select),
        .clk(pixel_clk)
    );
    wire gray_enable  = color_switch_val[3];
    wire red_enable   = color_switch_val[2];
    wire green_enable = color_switch_val[1];
    wire blue_enable  = color_switch_val[0];

    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;

    uart_receiver #(
        .CLOCK_FREQ(PIXEL_CLK_FREQ),
        .BAUD_RATE(115_200)) uart_rx (
        .clk(pixel_clk),
        .rst(reset),
        .data_out(uart_rx_data_out),             // output
        .data_out_valid(uart_rx_data_out_valid), // output
        .data_out_ready(uart_rx_data_out_ready), // input
        .serial_in(FPGA_SERIAL_RX)               // input
    );

    wire [7:0] ps_dout_data;
    wire ps_dout_valid, ps_dout_ready;
    wire [7:0] ps_din_data;
    wire ps_din_valid, ps_din_ready;

    pixel_stream pixel_stream (
        .pixel_clk(pixel_clk),                   // input
        .rst(1'b0),                              // input
        .read_en(SWITCHES[1] == 1),

        .pixel_stream_dout_data(ps_dout_data),   // output
        .pixel_stream_dout_valid(ps_dout_valid), // output
        .pixel_stream_dout_ready(ps_dout_ready), // input

        .pixel_stream_din_data(ps_din_data),     // input
        .pixel_stream_din_valid(ps_din_valid),   // input
        .pixel_stream_din_ready(ps_din_ready)    // output
    );

    wire [FIFO_WIDTH-1:0] fifo_enq_data, fifo_deq_data;
    wire fifo_enq_valid, fifo_enq_ready, fifo_deq_valid, fifo_deq_ready;

    fifo #(.WIDTH(FIFO_WIDTH), .LOGDEPTH (FIFO_LOGDEPTH)) FIFO (
        .clk(pixel_clk),
        .rst(1'b0),

        .enq_valid(fifo_enq_valid),  // input
        .enq_data(fifo_enq_data),    // input
        .enq_ready(fifo_enq_ready),  // output

        .deq_valid(fifo_deq_valid),  // output
        .deq_data(fifo_deq_data),    // output
        .deq_ready(fifo_deq_ready)); // input

    wire [23:0] dc_din_data;
    wire dc_din_valid, dc_din_ready;

    display_controller display_controller (
       .pixel_clk(pixel_clk),                 // input
       .pixel_stream_din_data(dc_din_data),   // input
       .pixel_stream_din_valid(dc_din_valid), // input
       .pixel_stream_din_ready(dc_din_ready), // output
       .video_out_pData(video_out_pData),     // output
       .video_out_pHSync(video_out_pHSync),   // output
       .video_out_pVSync(video_out_pVSync),   // output
       .video_out_pVDE(video_out_pVDE));      // output

    // uart_receiver (dout) <---> (din) pixel_stream (dout) <---> fifo <---> display controller (din)
    // R/V handshakes
    assign ps_din_data            = uart_rx_data_out;
    assign ps_din_valid           = uart_rx_data_out_valid;
    assign uart_rx_data_out_ready = ps_din_ready;

    assign fifo_enq_valid = ps_dout_valid;
    assign fifo_enq_data  = ps_dout_data;
    assign ps_dout_ready  = fifo_enq_ready;

    assign fifo_deq_ready = dc_din_ready;
    assign dc_din_valid   = fifo_deq_valid;
    assign dc_din_data    = (red_enable) ? {fifo_deq_data, 8'b0, 8'b0} :
                            (green_enable) ? {8'b0, 8'b0, fifo_deq_data} :
                            (blue_enable) ? {8'b0, fifo_deq_data, 8'b0} :
                            (gray_enable) ? {fifo_deq_data, fifo_deq_data, fifo_deq_data} :
                            {fifo_deq_data, fifo_deq_data, fifo_deq_data};

    // This register displays the received character using LEDS
    wire [7:0] led_test_val;
    REGISTER_R_CE #(.N(8), .INIT(0)) test_reg (
        .q(led_test_val),
        .d(uart_rx_data_out),
        .ce(uart_rx_data_out_valid & uart_rx_data_out_ready),
        .rst(reset),
        .clk(pixel_clk)
    );

    assign LEDS[3:0] = (SWITCHES[0] == 0) ? led_test_val[3:0] : led_test_val[7:4];
    assign LEDS[5:4] = 2'b11;

endmodule
