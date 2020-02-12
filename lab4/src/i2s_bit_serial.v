
module i2s_bit_serial #(
    parameter NUM_SAMPLE_BITS = 16
) (
    input serial_clk,
    input [NUM_SAMPLE_BITS-1:0] i2s_sample_data,
    output i2s_sample_sent,
    output i2s_sample_bit
);

    // This module sends individual bits of i2s_sample_data starting from MSB every serial_clk cycle
    // i2s_sample_sent should be HIGH when we finish sending all the bits of the current i2s_sample_data
    // TODO: Fill in the remaining logic

    wire [3:0] bit_cnt_reg_val, bit_cnt_reg_next;
    REGISTER #(.N(4)) bit_cnt_reg (.q(bit_cnt_reg_val), .d(bit_cnt_reg_next), .clk(serial_clk));

    wire [NUM_SAMPLE_BITS-1:0] sample_bit_reg_val, sample_bit_reg_next;
    REGISTER #(.N(NUM_SAMPLE_BITS)) sample_bit_reg (.q(sample_bit_reg_val), .d(sample_bit_reg_next), .clk(serial_clk));

endmodule
