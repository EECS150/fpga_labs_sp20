module uart_receiver #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input clk,
    input rst,

    // Dequeue the received character to the Sink
    output [7:0] data_out,
    output data_out_valid,
    input data_out_ready,

    // Serial bit input
    input serial_in
);
    // See diagram in the lab guide

    // For some reason, this offset value is needed to make the high-speed test work well
    // Unless you are sure of what you're doing, leave the offset as it is
    localparam OFFSET              = 10;
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE - OFFSET;
    localparam SAMPLE_TIME         = SYMBOL_EDGE_TIME / 2;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);

    (* mark_debug = "true" *) wire [9:0] rx_shift_val;
    wire [9:0] rx_shift_next;
    wire rx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) rx_shift (
        .q(rx_shift_val),
        .d(rx_shift_next),
        .ce(rx_shift_ce),
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
    wire is_sample_time = (clock_counter_val == SAMPLE_TIME - 1);

    // Note that UART protocol is asynchronous, the dequeue logic should be
    // inpedendent of the symbol/bit sample logic. You don't have to implement
    // a back-pressure handling (i.e., if data_out_ready is LOW for a long time)
    wire data_out_fire = data_out_valid & data_out_ready;

    // TODO: Fill in the remaining logic to implement the UART Receiver

endmodule
