`timescale 1ns/1ns

// You should not need to change this file
module z1top_uart_echo (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS,

    (* mark_debug = "true" *) input  FPGA_SERIAL_RX,
    (* mark_debug = "true" *) output FPGA_SERIAL_TX
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

    wire reset = (buttons_pressed[0] & SWITCHES[1]);

    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;

    uart_receiver #(
        .CLOCK_FREQ(125_000_000),
        .BAUD_RATE(115_200)) uart_rx (
        .clk(CLK_125MHZ_FPGA),
        .rst(reset),
        .data_out(uart_rx_data_out),             // output
        .data_out_valid(uart_rx_data_out_valid), // output
        .data_out_ready(uart_rx_data_out_ready), // input
        .serial_in(FPGA_SERIAL_RX)               // input
    );

    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;

    uart_transmitter #(
        .CLOCK_FREQ(125_000_000),
        .BAUD_RATE(115_200)) uart_tx (
        .clk(CLK_125MHZ_FPGA),
        .rst(reset),
        .data_in(uart_tx_data_in),             // input
        .data_in_valid(uart_tx_data_in_valid), // input
        .data_in_ready(uart_tx_data_in_ready), // output
        .serial_out(FPGA_SERIAL_TX)            // output
    );

    localparam FIFO_WIDTH    = 8;
    localparam FIFO_LOGDEPTH = 10;
    wire [FIFO_WIDTH-1:0] fifo_uart_enq_data, fifo_uart_deq_data;
    wire fifo_uart_enq_valid, fifo_uart_enq_ready, fifo_uart_deq_valid, fifo_uart_deq_ready;

    fifo #(.WIDTH(FIFO_WIDTH), .LOGDEPTH (FIFO_LOGDEPTH)) FIFO_UART (
        .clk(CLK_125MHZ_FPGA),
        .rst(reset),

        .enq_valid(fifo_uart_enq_valid),  // input
        .enq_data(fifo_uart_enq_data),    // input
        .enq_ready(fifo_uart_enq_ready),  // output

        .deq_valid(fifo_uart_deq_valid),  // output
        .deq_data(fifo_uart_deq_data),    // output
        .deq_ready(fifo_uart_deq_ready)); // input

    // FPGA_SERIAL_RX --> UART Receiver <--> FIFO_UART <--> UART Transmitter --> FPGA_SERIAL_TX
    // R/V Handshakes
    assign fifo_uart_enq_data     = uart_rx_data_out;
    assign fifo_uart_enq_valid    = uart_rx_data_out_valid;
    assign uart_rx_data_out_ready = fifo_uart_enq_ready;

    assign uart_tx_data_in        = fifo_uart_deq_data;
    assign uart_tx_data_in_valid  = fifo_uart_deq_valid;
    assign fifo_uart_deq_ready    = uart_tx_data_in_ready;

    assign LEDS[5:4] = 2'b11;
endmodule
