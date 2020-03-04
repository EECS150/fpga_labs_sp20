`include "color.vh"

module draw_triangle #(
//    // Video resolution parameters for 800x600 @60Hz -- pixel_freq = 40 MHz
//    parameter H_ACTIVE_VIDEO = 800,
//    parameter H_FRONT_PORCH  = 40,
//    parameter H_SYNC_WIDTH   = 128,
//    parameter H_BACK_PORCH   = 88,
//
//    parameter V_ACTIVE_VIDEO = 600,
//    parameter V_FRONT_PORCH  = 1,
//    parameter V_SYNC_WIDTH   = 4,
//    parameter V_BACK_PORCH   = 23

    // Video resolution parameters for 1024x768 @60Hz -- pixel_freq = 65 MHz
    parameter H_ACTIVE_VIDEO = 1024,
    parameter H_FRONT_PORCH  = 24,
    parameter H_SYNC_WIDTH   = 136,
    parameter H_BACK_PORCH   = 160,

    parameter V_ACTIVE_VIDEO = 768,
    parameter V_FRONT_PORCH  = 3,
    parameter V_SYNC_WIDTH   = 6,
    parameter V_BACK_PORCH   = 29
) (
    input pixel_clk,

    // Pixel coordinates of the three vertices of the triangle
    input [31:0] x0,
    input [31:0] y0,
    input [31:0] x1,
    input [31:0] y1,
    input [31:0] x2,
    input [31:0] y2,

    // video signals
    output [23:0] video_out_pData,
    output video_out_pHSync,
    output video_out_pVSync,
    output video_out_pVDE
);

    localparam H_FRAME = H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
    localparam V_FRAME = V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;

    wire [31:0] x_pixel_val, x_pixel_next;
    wire x_pixel_ce, x_pixel_rst;
    wire [31:0] y_pixel_val, y_pixel_next;
    wire y_pixel_ce, y_pixel_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) x_pixel (
        .q(x_pixel_val),
        .d(x_pixel_next),
        .ce(x_pixel_ce),
        .rst(x_pixel_rst),
        .clk(pixel_clk));
    REGISTER_R_CE #(.N(32), .INIT(0)) y_pixel (
        .q(y_pixel_val),
        .d(y_pixel_next),
        .ce(y_pixel_ce),
        .rst(y_pixel_rst),
        .clk(pixel_clk));

    wire [31:0] x_pixel_out, y_pixel_out;
    wire is_inside;

    // The point_in_triangle module is essentially a pipeline
    // Depending on how many pipeline stages you added, it will take
    // some cycles from when a pixel enters the pipeline to when the test result
    // is available
    point_in_triangle point_in_triangle (
        // Inputs
        .pixel_clk(pixel_clk),
        .x_pixel(x_pixel_val),
        .y_pixel(y_pixel_val),
        .x0(x0),
        .y0(y0),
        .x1(x1),
        .y1(y1),
        .x2(x2),
        .y2(y2),

        // Outputs
        .x_pixel_out(x_pixel_out),
        .y_pixel_out(y_pixel_out),
        .is_inside(is_inside)
    );

    wire [23:0] pixel_color = (is_inside) ? `MAGENTA : `BLACK;
    // For rgb2dvi IP, G and B are actually swapped
    assign video_out_pData = {pixel_color[23:16], pixel_color[7:0], pixel_color[15:8]};


    // TODO: Correct the following assign statements
    // The logic is similar to the display_controller module.
    // However, for video signals, you need to use x_pixel_out and y_pixel_out

    assign x_pixel_next = 1'b1;
    assign x_pixel_ce   = 1'b1;
    assign x_pixel_rst  = 1'b1;

    assign y_pixel_next = 1'b1;
    assign y_pixel_ce   = 1'b1;
    assign y_pixel_rst  = 1'b1;

    assign video_out_pHSync = 1'b1;
    assign video_out_pVSync = 1'b1;
    assign video_out_pVDE   = 1'b1;

endmodule
