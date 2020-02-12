
module sum_sync_mem #(
    parameter AWIDTH = 10,
    parameter DWIDTH = 32,
    parameter DEPTH =  1024,
    parameter MEM_INIT_HEX_FILE = ""
) (
    input clk,
    input reset,
    output done,
    input [31:0] size,
    output [31:0] sum
);

    // TODO: Fill in the remaining logic to compute the sum of memory data from 0 to 'size'
    // Note that in this case, memory read takes one cycle
    wire [AWIDTH-1:0] rom_addr;
    wire [DWIDTH-1:0] rom_rdata;
    SYNC_ROM #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .MEM_INIT_HEX_FILE(MEM_INIT_HEX_FILE)
    ) rom (.addr(rom_addr), .q(rom_rdata), .clk(clk));

    wire [31:0] index_reg_val, index_reg_next;
    wire index_reg_rst, index_reg_ce;
    REGISTER_R_CE #(.N(32)) index_reg (.q(index_reg_val), .d(index_reg_next), .ce(index_reg_ce), .rst(index_reg_rst), .clk(clk));

    wire [31:0] sum_reg_val, sum_reg_next;
    wire sum_reg_rst, sum_reg_ce;
    REGISTER_R_CE #(.N(32)) sum_reg (.q(sum_reg_val), .d(sum_reg_next), .ce(sum_reg_ce), .rst(sum_reg_rst), .clk(clk));

endmodule
