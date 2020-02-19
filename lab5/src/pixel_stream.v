`include "../../lib/EECS151.v"

// This block keeps streaming pixels from the ROM to the sink block
// as long as the sink block is ready
module pixel_stream #(
    parameter IMG_ADDR_WIDTH = 19,
    parameter IMG_DATA_WIDTH = 8,
    parameter IMG_NUM_PIXELS = 600 * 800
) (
    input pixel_clk,
    input rst,

    output [IMG_DATA_WIDTH-1:0] pixel_stream_data,
    output pixel_stream_valid,
    input pixel_stream_ready
);
    wire [IMG_ADDR_WIDTH-1:0] img_mem_addr;
    wire [IMG_DATA_WIDTH-1:0] img_mem_rdata;
    SYNC_ROM #(
        .AWIDTH(IMG_ADDR_WIDTH),
        .DWIDTH(IMG_DATA_WIDTH),
        .DEPTH(IMG_NUM_PIXELS),
        .MEM_INIT_BIN_FILE("ucb_wheeler_hall_bin.mif")
    ) img_memory (
        .q(img_mem_rdata), .addr(img_mem_addr), .clk(pixel_clk));

    wire pixel_stream_fire = pixel_stream_valid & pixel_stream_ready;

    wire [IMG_ADDR_WIDTH-1:0] pixel_index_val, pixel_index_next;
    wire pixel_index_ce, pixel_index_rst;

    REGISTER_R_CE #(.N(IMG_ADDR_WIDTH), .INIT(0)) pixel_index (
        .q(pixel_index_val),
        .d(pixel_index_next),
        .ce(pixel_index_ce),
        .rst(pixel_index_rst),
        .clk(pixel_clk));

    assign pixel_index_next = pixel_index_val + 1;
    assign pixel_index_ce = pixel_stream_fire;
    assign pixel_index_rst = (pixel_index_val == IMG_NUM_PIXELS - 1) | rst;

    // Delay 1 cycle because SYNC_ROM has one-cycle read
    wire delay_val;
    REGISTER_R #(.N(1), .INIT(0)) delay (.q(delay_val), .d(1'b1), .rst(rst), .clk(pixel_clk));
    assign pixel_stream_valid = (delay_val == 1'b1);
    assign pixel_stream_data = img_mem_rdata;
    assign img_mem_addr = pixel_index_val;

endmodule
