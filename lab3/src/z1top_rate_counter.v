`timescale 1ns/1ns
`include "../../lib/EECS151.v"
`define CLOCK_FREQ 125_000_000

module z1top_rate_counter (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS
);
    assign LEDS[5:4] = 2'b11;

    // TODO: Your code to implement a 4-bit counter of rate 1 Hz (counting up)
    // or a parameterized rate counter. You can reuse the code in previous exercises
    // Use the buttons to provide control signals to your counter (refer to the spec)
    // You might want to use additional registers to keep track of the current state
    // of your counter

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

endmodule
