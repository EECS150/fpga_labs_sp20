`timescale 1ns/1ns

module z1top_tone_generator_tb();
    localparam CLK_FREQ = 125_000_000;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;
    localparam NUM_SAMPLE_BITS = 16;
    localparam NUM_SAMPLES = 65536;

    reg clock;
    initial clock = 0;
    always #(CLK_PERIOD / 2) clock <= ~clock;

    reg [NUM_SAMPLE_BITS-1:0] mem_data[NUM_SAMPLES-1:0];

    reg [3:0] buttons = 4'b1111;
    reg [1:0] switches = 2'b11;
    wire [5:0] leds;

    wire mclk, lrck, sclk, sdout;
    reg [NUM_SAMPLE_BITS-1:0] data_bit;

    z1top_tone_generator dut (
        .CLK_125MHZ_FPGA(clock),
        .BUTTONS(buttons),
        .SWITCHES(switches),
        .LEDS(leds),
        .PMOD_OUT_PIN1(mclk),
        .PMOD_OUT_PIN2(lrck),
        .PMOD_OUT_PIN3(sclk),
        .PMOD_OUT_PIN4(sdout)
    );

    integer i = 0;
    integer num_mismatches = 0;
    integer test_done = 0;

    // This testbench assumes that we send the serial bit at the rising edge of sclk
    // And we expect that we can send all 16 bits of an audio frame (MSB->LSB)
    // within one-half period of lrck (verify that in the waveform).
    // Note that we send a sample twice in one period of lrck.
    // If you adopt a different strategy, you may want to change the following code.
    // (but it might be helpful by just checking with this first)
    // This test will take a while to finish (3-5 mins). You should stop it when you start seeing mismatched results
    initial begin
       #0;
       data_bit = 0;
       $readmemb("tone_440_data_bin.mif", mem_data);

       for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
           // Assemble the bits as soon as the rising edge of sclk arrives
           // for 16 sclk cycles.
           // This gives us one audio sample data.
           repeat (16) begin
               // add #1 because of Verilog oddity
               @(posedge sclk); #1;
               // from MSB to LSB
               data_bit = (data_bit << 1) | sdout;
           end

           // Now, we check if the received audio sample data matches the audio data
           // in the mif file.
           // We use mem_data[i / 2] for both left and right channels.
           if (data_bit != mem_data[i / 2]) begin
               num_mismatches = num_mismatches + 1;
               $display("At time %d, Mismatch: %b %b\n", $time, data_bit, mem_data[i / 2]);
           end
       end

       test_done = 1;
       if (num_mismatches == 0)
           $display("TEST PASSED!\n");
       else
           $display("TEST FAILED: num_mismatches = %d\n", num_mismatches);
       #1000;
       $finish();
    end

    initial begin
        // wait for 1 second; it shouldn't take this long
        #(1_000_000_000);
        $display("TIMEOUT");
        $finish();
    end
endmodule
