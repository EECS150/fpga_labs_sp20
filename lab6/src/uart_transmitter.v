module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input rst,

    // Enqueue the to-be-sent character
    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    // Serial bit output
    output serial_out
);
    // See diagram in the lab guide
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);

    (* mark_debug = "true" *) wire [9:0] tx_shift_val;
    wire [9:0] tx_shift_next;
    wire tx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) tx_shift (
        .q(tx_shift_val),
        .d(tx_shift_next),
        .ce(tx_shift_ce),
        .clk(clk));

    (* mark_debug = "true" *) wire [3:0] bit_counter_val;
    wire [3:0] bit_counter_next;
    wire bit_counter_ce, bit_counter_rst;

    // Count to 10
    REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
        .q(bit_counter_val),
        .d(bit_counter_next),
        .ce(bit_counter_ce),
        .rst(bit_counter_rst),
        .clk(clk)
    );

    (* mark_debug = "true" *) wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce, clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );

    wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);

    wire data_in_fire = data_in_valid & data_in_ready;

    // TODO: Fill in the remaining logic to implement the UART Receiver

endmodule
