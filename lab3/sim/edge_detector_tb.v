`timescale 1ns/1ps

`define CLK_PERIOD 8
`define EDGE_DETECTOR_WIDTH 1

module edge_detector_tb();
    // Generate 125 MHz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    // I/O of edge detector
    reg [`EDGE_DETECTOR_WIDTH-1:0] signal_in;
    wire [`EDGE_DETECTOR_WIDTH-1:0] edge_detect_pulse;

    edge_detector #(
        .WIDTH(`EDGE_DETECTOR_WIDTH)
    ) DUT (
        .clk(clk),
        .signal_in(signal_in),
        .edge_detect_pulse(edge_detect_pulse)
    );

    reg done = 0;
    reg [31:0] tests_failed = 0;

    initial begin
        #0;
        signal_in = 0;
        #50;
        signal_in = 1;
        #30;
        signal_in = 0;
        #30;
        signal_in = 1;
        #400;

        $display("Timeout! Failed.");
        $finish();
    end
    
    initial begin
        // Wait for the rising edge of the edge detector output
        @(posedge edge_detect_pulse);

        // Let 1 clock cycle elapse (#1 is a Verilog oddity since the edge_detect_pulse should change right after
        // the rising clock edge, not at the same instant as the rising edge).
        @(posedge clk); #1;

        // Check that the edge detector output is now low
        if (edge_detect_pulse[0] !== 1'b0) begin
            $display("Failure 1: Your edge detector's output wasn't 1 clock cycle wide");
            tests_failed = tests_failed + 1;
        end
      
        // Wait for the 2nd rising edge, and same logic
        @(posedge edge_detect_pulse);
        @(posedge clk); #1;
        if (edge_detect_pulse[0] !== 1'b0) begin
            $display("Failure 2: Your edge detector's output wasn't 1 clock cycle wide");
            tests_failed = tests_failed + 1;
        end
        done = 1;
    end
    
    always @(posedge edge_detect_pulse) begin
      $display("Detect rising edge at time %d!", $time);
    end
    
    always @(posedge clk) begin
      if (done == 1 && tests_failed == 0) begin
          $display("All tests passed!");
          $finish();
      end
    end

endmodule
