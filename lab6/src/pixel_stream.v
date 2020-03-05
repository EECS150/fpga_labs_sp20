// This block keepixel_stream streaming pixels from the ROM to the sink block
// as long as the sink block is ready
module pixel_stream #(
    parameter IMG_ADDR_WIDTH = 19,
    parameter IMG_DATA_WIDTH = 8,
    parameter IMG_NUM_PIXELS = 600 * 800
) (
    input pixel_clk,
    input rst,

    input read_en,

    input [IMG_DATA_WIDTH-1:0] pixel_stream_din_data,
    input pixel_stream_din_valid,
    output pixel_stream_din_ready,

    output [IMG_DATA_WIDTH-1:0] pixel_stream_dout_data,
    output pixel_stream_dout_valid,
    input pixel_stream_dout_ready
);

    assign pixel_stream_din_ready = 1'b1;
    wire pixel_stream_din_fire = pixel_stream_din_valid & pixel_stream_din_ready;
    wire pixel_stream_dout_fire = pixel_stream_dout_valid & pixel_stream_dout_ready;

    wire [IMG_ADDR_WIDTH-1:0] img_mem_addr0, img_mem_addr1;
    wire [IMG_DATA_WIDTH-1:0] img_mem_rdata0, img_mem_rdata1;
    wire [IMG_DATA_WIDTH-1:0] img_mem_wdata0, img_mem_wdata1;
    wire img_mem_we0, img_mem_we1;

    XILINX_SYNC_RAM_DP #(
        .AWIDTH(IMG_ADDR_WIDTH),
        .DWIDTH(IMG_DATA_WIDTH),
        .DEPTH(IMG_NUM_PIXELS),
        .MEM_INIT_BIN_FILE("ucb_wheeler_hall_bin.mif")
    ) img_memory (
        .q0(img_mem_rdata0),
        .d0(img_mem_wdata0),
        .addr0(img_mem_addr0),
        .we0(img_mem_we0),

        .q1(img_mem_rdata1),
        .d1(img_mem_wdata1),
        .addr1(img_mem_addr1),
        .we1(img_mem_we1),

        .clk(pixel_clk),
        .rst(rst)
    );

    // The assumption is that the Source block will keep firing pixels
    assign img_mem_we0 = pixel_stream_din_fire;

    // Disable write on port 1
    assign img_mem_we1 = 1'b0;
    assign img_mem_wdata1 = 0;

    wire [IMG_ADDR_WIDTH-1:0] pixel_read_index_val, pixel_read_index_next;
    wire pixel_read_index_ce, pixel_read_index_rst;

    REGISTER_R_CE #(.N(IMG_ADDR_WIDTH), .INIT(0)) pixel_read_index (
        .q(pixel_read_index_val),
        .d(pixel_read_index_next),
        .ce(pixel_read_index_ce),
        .rst(pixel_read_index_rst),
        .clk(pixel_clk));

    wire [IMG_ADDR_WIDTH-1:0] pixel_write_index_val, pixel_write_index_next;
    wire pixel_write_index_ce, pixel_write_index_rst;

    REGISTER_R_CE #(.N(IMG_ADDR_WIDTH), .INIT(0)) pixel_write_index (
        .q(pixel_write_index_val),
        .d(pixel_write_index_next),
        .ce(pixel_write_index_ce),
        .rst(pixel_write_index_rst),
        .clk(pixel_clk));

    wire read_en_val;
    REGISTER_R_CE #(.N(1), .INIT(0)) read_en_reg (
        .q(read_en_val),
        .d(1'b1),
        .ce(read_en),
        .rst(rst), .clk(pixel_clk));

    wire delay_val;
    // Delay 1 cycle due to synchronous read
    REGISTER #(.N(1)) delay (.q(delay_val), .d(read_en_val), .clk(pixel_clk));

    assign pixel_read_index_next = pixel_read_index_val + 1;
    assign pixel_read_index_ce = read_en_val & pixel_stream_dout_ready;
    assign pixel_read_index_rst = (pixel_read_index_val == IMG_NUM_PIXELS - 1) | rst;

    assign pixel_write_index_next = pixel_write_index_val + 1;
    assign pixel_write_index_ce = pixel_stream_din_fire;
    assign pixel_write_index_rst = (pixel_write_index_val == IMG_NUM_PIXELS - 1) | rst;

    assign img_mem_addr0 = pixel_write_index_val;
    assign img_mem_wdata0 = pixel_stream_din_data;

    assign img_mem_addr1 = pixel_read_index_val;

    assign pixel_stream_dout_valid = (delay_val == 1'b1);
    assign pixel_stream_dout_data = img_mem_rdata1;

endmodule
