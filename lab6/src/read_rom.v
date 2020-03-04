
module read_rom (
    input clk,
    input rst,
    input read_en,

    output [7:0] rdata_out,
    output rdata_out_valid,
    input  rdata_out_ready
);

    localparam AWIDTH = 7;
    localparam DWIDTH = 8;
    localparam DEPTH  = 105;

    wire rdata_out_fire = rdata_out_valid & rdata_out_ready;

    wire [AWIDTH-1:0] mem_addr;
    wire [DWIDTH-1:0] mem_rdata;

    SYNC_ROM #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE("text.mif")
    ) mem (.q(mem_rdata), .addr(mem_addr), .clk(clk));

    REGISTER_R_CE #(.N(AWIDTH), .INIT(0)) mem_addr_reg (
        .q(mem_addr),
        .d(mem_addr + 1),
        .ce(rdata_out_fire),
        .rst(rst),
        .clk(clk));

    // Delay 1 cycle because SYNC_ROM has one-cycle read
    wire delay_val;
    REGISTER_R_CE #(.N(1), .INIT(0)) delay (
        .q(delay_val), .d(1'b1), .rst(rst), .ce(read_en), .clk(clk));

    assign rdata_out_valid = delay_val & (mem_addr < DEPTH);
    assign rdata_out = mem_rdata;

endmodule
