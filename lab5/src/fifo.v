`include "../../lib/EECS151.v"

module fifo #(
    parameter WIDTH = 32,  // data width is 32-bit
    parameter LOGDEPTH = 3 // 2^3 = 8 entries
) (
    input clk,
    input rst,

    input  enq_valid,
    input  [WIDTH-1:0] enq_data,
    output enq_ready,

    output deq_valid,
    output [WIDTH-1:0] deq_data,
    input deq_ready
);

    // For simplicity, we deal with FIFO with depth values of power of two.
    localparam DEPTH = (1 << LOGDEPTH);

    // Dual-port Memory
    // Use port0 for write, port1 for read
    wire [LOGDEPTH-1:0] buffer_addr0, buffer_addr1;
    wire [WIDTH-1:0] buffer_d0, buffer_d1, buffer_q0, buffer_q1;
    wire buffer_we0, buffer_we1;

    // You can choose to use either ASYNC read or SYNC read memory for buffer storage of your FIFO
    // It is suggested that you should start with ASYNC read, since it will be simpler

    // This memory requires 1-cycle write update
    // Read can be performed immediately
    XILINX_ASYNC_RAM_DP #(.AWIDTH(LOGDEPTH), .DWIDTH(WIDTH), .DEPTH(DEPTH)) buffer (
        .q0(buffer_q0), .d0(buffer_d0), .addr0(buffer_addr0), .we0(buffer_we0),
        .q1(buffer_q1), .d1(buffer_d1), .addr1(buffer_addr1), .we1(buffer_we1),
        .clk(clk), .rst(rst));

//    // This memory requires 1-cycle write, and 1-cycle read
//    XILINX_SYNC_RAM_DP #(.AWIDTH(LOGDEPTH), .DWIDTH(WIDTH), .DEPTH(DEPTH)) buffer (
//        .q0(buffer_q0), .d0(buffer_d0), .addr0(buffer_addr0), .we0(buffer_we0),
//        .q1(buffer_q1), .d1(buffer_d1), .addr1(buffer_addr1), .we1(buffer_we1),
//        .clk(clk), .rst(rst));

    // Disable write on port1
    assign buffer_we1 = 1'b0;
    assign buffer_d1  = 0;

    wire [LOGDEPTH-1:0] read_ptr_val, read_ptr_next;
    wire read_ptr_ce;
    wire [LOGDEPTH-1:0] write_ptr_val, write_ptr_next;
    wire write_ptr_ce;

    REGISTER_R_CE #(.N(LOGDEPTH)) read_ptr_reg  (
        .q(read_ptr_val),
        .d(read_ptr_next),
        .ce(read_ptr_ce),
        .rst(rst), .clk(clk));
    REGISTER_R_CE #(.N(LOGDEPTH)) write_ptr_reg (
        .q(write_ptr_val),
        .d(write_ptr_next),
        .ce(write_ptr_ce),
        .rst(rst), .clk(clk));

    // TODO: Your code to implement the FIFO logic
    // Note that:
    // - enq_ready is LOW: FIFO is full
    // - deq_valid is LOW: FIFO is empty

    wire enq_fire = enq_valid && enq_ready;
    wire deq_fire = deq_valid && deq_ready;


endmodule
