`timescale 1ns/1ns
`include "../../lib/EECS151.v"

module z1top_fifo_display (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,

    output pixel_clk,

    // video signals
    output [23:0] video_out_pData,
    output video_out_pHSync,
    output video_out_pVSync,
    output video_out_pVDE
);
    wire clk_in1, clk_out1;
    assign pixel_clk = clk_out1;
    assign clk_in1 = CLK_125MHZ_FPGA;

    // Clocking wizard IP from Vivado (wrapper of the PLLE module)
    // Generate 40 MHz clock from 125 MHz clock
    // The 40 MHz clock is used as pixel clock
    clk_wiz clk_wiz (
        .clk_out1(clk_out1), // output
        .reset(1'b0),        // input
        .locked(),           // output, unused
        .clk_in1(clk_in1)    // input
    );


    // Button parser
    // Sample the button signal every 500us
    localparam integer B_SAMPLE_CNT_MAX = 0.0005 * 40_000_000;
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

    wire gray_enable, red_enable, green_enable, blue_enable;
    wire gray_select = buttons_pressed[3];
    wire red_select = buttons_pressed[2];
    wire green_select = buttons_pressed[1];
    wire blue_select = buttons_pressed[0];

    REGISTER_R_CE #(.N(1)) gray_enable_r (.q(gray_enable), .d(1'b1), 
        .ce(gray_select), .rst(red_select | green_select | blue_select), .clk(pixel_clk));
    REGISTER_R_CE #(.N(1)) red_enable_r (.q(red_enable), .d(1'b1), 
        .ce(red_select), .rst(gray_select | green_select | blue_select), .clk(pixel_clk));
    REGISTER_R_CE #(.N(1)) green_enable_r (.q(green_enable), .d(1'b1), 
        .ce(green_select), .rst(gray_select | red_select | blue_select), .clk(pixel_clk));
    REGISTER_R_CE #(.N(1)) blue_enable_r (.q(blue_enable), .d(1'b1), 
        .ce(blue_select), .rst(gray_select | red_select | green_select), .clk(pixel_clk));

    wire [7:0] pixel_stream_dout_data;
    wire pixel_stream_dout_valid, pixel_stream_dout_ready;

    pixel_stream pixel_stream (
        .pixel_clk(pixel_clk),                              // input
        .rst(1'b0),                                         // input
        .pixel_stream_dout_data(pixel_stream_dout_data),    // output
        .pixel_stream_dout_valid(pixel_stream_dout_valid),  // output
        .pixel_stream_dout_ready(pixel_stream_dout_ready)   // input
    );

    localparam FIFO_WIDTH = 8;
    localparam FIFO_LOGDEPTH = 10;

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

    wire [23:0] pixel_stream_din_data;
    wire pixel_stream_din_valid, pixel_stream_din_ready;

    display_controller display_controller (
       .pixel_clk(pixel_clk),                           // input
       .pixel_stream_din_data(pixel_stream_din_data),   // input
       .pixel_stream_din_valid(pixel_stream_din_valid), // input
       .pixel_stream_din_ready(pixel_stream_din_ready), // output
       .video_out_pData(video_out_pData),               // output
       .video_out_pHSync(video_out_pHSync),             // output
       .video_out_pVSync(video_out_pVSync),             // output
       .video_out_pVDE(video_out_pVDE));                // output

    // pixel_stream (dout) <---> fifo <---> display controller (din)
    // Connecting these blocks is just a matter of conveniently hooking up 
    // relevant signals from both ends
    // (valid goes with valid, ready goes with ready, data goes with data)
    assign fifo_enq_valid          = pixel_stream_dout_valid;
    assign fifo_enq_data           = pixel_stream_dout_data;
    assign pixel_stream_dout_ready = fifo_enq_ready;

    assign fifo_deq_ready          = pixel_stream_din_ready;
    assign pixel_stream_din_valid  = fifo_deq_valid;
    assign pixel_stream_din_data   = (red_enable) ? {fifo_deq_data, 8'b0, 8'b0} :
                                     (green_enable) ? {8'b0, 8'b0, fifo_deq_data} :
                                     (blue_enable) ? {8'b0, fifo_deq_data, 8'b0} :
                                     (gray_enable) ? {fifo_deq_data, fifo_deq_data, fifo_deq_data} :
                                     {fifo_deq_data, fifo_deq_data, fifo_deq_data};

   assign LEDS[3:0] = {gray_enable, red_enable, green_enable, blue_enable};
endmodule
