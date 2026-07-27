`timescale 1ns/1ps

module tb_top;

    // ------------------------------------------------------------------
    // DUT port signals
    // ------------------------------------------------------------------
    logic        clk;
    logic        rst;
    logic        start_ext;
    logic [0:0]  output_ext;
    logic        valid_output_ext;

    // Clock period definition
    localparam CLK_PERIOD = 10;  // ns

    // ------------------------------------------------------------------
    // Instantiate the DUT
    // ------------------------------------------------------------------
    top uut1 (
        .clk             (clk),
        .rst             (rst),
        .start_ext       (start_ext),
        .output_ext      (output_ext),
        .valid_output_ext(valid_output_ext)
    );

    // ------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ------------------------------------------------------------------
    // Stimulus process
    // ------------------------------------------------------------------
    initial begin
        // Initial values
        rst       = 1'b1;
        start_ext = 1'b0;

        // Hold reset for 100 ns
        #100;
        rst = 1'b0;

        // Wait 100 ns, then apply start pulse
        #100;
        start_ext = 1'b1;
        #100;
        start_ext = 1'b0;
    end

endmodule

