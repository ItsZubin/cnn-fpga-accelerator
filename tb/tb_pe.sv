// ---------------------------------------------------------------------------
// Self-checking testbench for PE (processing element).
//
// Reference model: the PE gates each 4-bit signed weight with the
// corresponding activation bit taken from a 4-bit sliding window into the
// 64-bit feature map, then sums the four results into an 8-bit signed value
// and registers it.
//
//   window = (start_pe && count_PE <= 60) ? ifmap[count_PE +: 4] : 4'b0
//   Psum   <= sum over i of (window[i] ? $signed(weights[i]) : 0)
//
// No overflow is possible: four weights in [-8, +7] sum to at most +28 and
// at least -32, both well inside 8-bit signed range. The test asserts that
// property directly rather than assuming it.
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_pe;

    localparam int CLK_PERIOD = 10;
    localparam int N_RANDOM   = 2000;

    logic              clk = 0;
    logic              rst;
    logic              start_pe;
    logic [63:0]       ifmap;
    logic [7:0]        count_PE;
    logic signed [3:0] weights [0:3];
    logic signed [7:0] Psum;

    int unsigned errors  = 0;
    int unsigned checks  = 0;

    PE dut (
        .clk      (clk),
        .rst      (rst),
        .start_pe (start_pe),
        .ifmap    (ifmap),
        .count_PE (count_PE),
        .weights  (weights),
        .Psum     (Psum)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // --- reference model ---------------------------------------------------
    function automatic signed [7:0] ref_psum(
        input logic              i_start,
        input logic [63:0]       i_ifmap,
        input logic [7:0]        i_count,
        input logic signed [3:0] i_w [0:3]
    );
        logic [3:0]        window;
        logic signed [7:0] acc;
        window = (i_start && (i_count <= 8'd60)) ? i_ifmap[i_count +: 4] : 4'b0;
        acc = 8'sd0;
        for (int i = 0; i < 4; i++)
            if (window[i]) acc = acc + i_w[i];
        return acc;
    endfunction

    // --- checker -----------------------------------------------------------
    task automatic check(input string tag);
        logic signed [7:0] expected;
        expected = ref_psum(start_pe, ifmap, count_PE, weights);
        @(posedge clk);          // sample the value the DUT registers
        #1;                      // settle past the non-blocking update
        checks++;
        if (Psum !== expected) begin
            errors++;
            $error("[%s] count_PE=%0d start=%0b  expected Psum=%0d, got %0d",
                   tag, count_PE, start_pe, expected, Psum);
        end
        // Range property: the accumulator must never leave [-32, +28].
        if (expected > 8'sd28 || expected < -8'sd32) begin
            errors++;
            $error("[%s] reference model produced out-of-range Psum=%0d",
                   tag, expected);
        end
    endtask

    task automatic drive(input logic              i_start,
                         input logic [63:0]       i_ifmap,
                         input logic [7:0]        i_count,
                         input logic signed [3:0] i_w [0:3]);
        start_pe = i_start;
        ifmap    = i_ifmap;
        count_PE = i_count;
        weights  = i_w;
    endtask

    initial begin
        logic signed [3:0] w [0:3];

        rst      = 1'b1;
        start_pe = 1'b0;
        ifmap    = '0;
        count_PE = '0;
        for (int i = 0; i < 4; i++) weights[i] = '0;

        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // --- reset behaviour ------------------------------------------------
        if (Psum !== 8'sd0) begin
            errors++;
            $error("[reset] Psum should be 0 after reset, got %0d", Psum);
        end
        checks++;

        // --- directed: all-ones window, maximum positive weights ------------
        w[0] = 4'sd7; w[1] = 4'sd7; w[2] = 4'sd7; w[3] = 4'sd7;
        drive(1'b1, {64{1'b1}}, 8'd0, w);
        check("max-positive");

        // --- directed: all-ones window, maximum negative weights ------------
        w[0] = -4'sd8; w[1] = -4'sd8; w[2] = -4'sd8; w[3] = -4'sd8;
        drive(1'b1, {64{1'b1}}, 8'd0, w);
        check("max-negative");

        // --- directed: zero activations must zero the result ----------------
        w[0] = 4'sd7; w[1] = -4'sd8; w[2] = 4'sd3; w[3] = -4'sd1;
        drive(1'b1, 64'd0, 8'd0, w);
        check("zero-activations");

        // --- directed: start_pe low must force the window to zero -----------
        drive(1'b0, {64{1'b1}}, 8'd0, w);
        check("start-low");

        // --- directed: every legal window position --------------------------
        for (int c = 0; c <= 60; c++) begin
            w[0] = 4'sd1; w[1] = 4'sd2; w[2] = 4'sd4; w[3] = -4'sd8;
            drive(1'b1, 64'hA5A5_5A5A_C3C3_3C3C, c[7:0], w);
            check($sformatf("window-pos-%0d", c));
        end

        // --- directed: out-of-range positions must gate to zero -------------
        for (int c = 61; c <= 70; c++) begin
            w[0] = 4'sd7; w[1] = 4'sd7; w[2] = 4'sd7; w[3] = 4'sd7;
            drive(1'b1, {64{1'b1}}, c[7:0], w);
            check($sformatf("out-of-range-%0d", c));
        end

        // --- randomised ------------------------------------------------------
        for (int n = 0; n < N_RANDOM; n++) begin
            for (int i = 0; i < 4; i++)
                w[i] = $urandom_range(0, 15);
            drive($urandom_range(0, 1),
                  {$urandom, $urandom},
                  $urandom_range(0, 70),
                  w);
            check($sformatf("random-%0d", n));
        end

        // --- report -----------------------------------------------------------
        $display("");
        $display("---------------------------------------------");
        $display(" tb_pe: %0d checks, %0d failures", checks, errors);
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("---------------------------------------------");
        if (errors != 0) $fatal(1, "tb_pe failed");
        $finish;
    end

endmodule
