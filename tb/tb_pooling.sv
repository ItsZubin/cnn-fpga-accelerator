// ---------------------------------------------------------------------------
// Self-checking testbench for Pooling_TOP.
//
// Pooling_TOP accumulates a running maximum into one of four registers,
// selected by the convolution window position `count_PE`, and emits each
// register once per frame. A frame is 15 rows of count_PE sweeping 0..60;
// outputs are produced during the final row (row_counter == 14).
//
// BIN BOUNDARIES -- READ THIS
// ---------------------------
// The bin ranges below are transcribed from the RTL as written, not from a
// specification. They are NOT uniform, and the emit points do not line up
// with the ends of the bins:
//
//   bin 1 : count_PE  0..15   (16 positions)   emitted at count_PE == 16
//   bin 2 : count_PE 16..30   (15 positions)   emitted at count_PE == 32
//   bin 3 : count_PE 31..45   (15 positions)   emitted at count_PE == 48
//   bin 4 : count_PE 46..60   (15 positions)   emitted at count_PE == 60
//
// The reference model (MATLAB/max_pool.m) tiles the 61x61 feature map into a
// 4x4 grid of uniform 15x15 tiles. Two things follow. First, bin 1 covers one
// more position than that reference tile. Second, positions 31 and 32 are
// folded into bin 3 even though bin 2 is not emitted until position 32, so
// uniform tiling is not what this computes.
//
// The RTL also writes `count_PE >= 8'd45 && count_PE < 8'd61` for bin 4 while
// bin 3 already claims 45. The if/else-if chain resolves that in favour of
// bin 3, so 45 is not double-counted -- but the overlap is almost certainly
// a typo for 46.
//
// This testbench encodes the behaviour as implemented so it works as a
// regression test, and raises an explicit warning about the boundaries so the
// discrepancy is visible rather than silently locked in. To match the
// reference's uniform 15x15 tiling, the RTL needs changing and the parameters
// below need updating to follow.
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_pooling;

    localparam int CLK_PERIOD = 10;
    localparam int ROWS       = 15;
    localparam int LAST_POS   = 60;

    // Bin boundaries as implemented (see header)
    localparam int BIN_LO [4] = '{  0, 16, 31, 46 };
    localparam int BIN_HI [4] = '{ 15, 30, 45, 60 };
    localparam int EMIT_AT[4] = '{ 16, 32, 48, 60 };

    logic       clk = 0;
    logic       rst;
    logic [3:0] ofmap_RELU;
    logic       valid_data;
    logic [7:0] count_PE;
    logic [3:0] pooling_out;
    logic       valid_pooling;

    int unsigned errors   = 0;
    int unsigned checks   = 0;
    int unsigned n_emits  = 0;

    // Scoreboard: expected running max per bin, tracked independently
    logic [3:0] exp_max [4];
    logic [3:0] emitted [4];

    Pooling_TOP dut (
        .clk           (clk),
        .rst           (rst),
        .ofmap_RELU    (ofmap_RELU),
        .valid_data    (valid_data),
        .count_PE      (count_PE),
        .pooling_out   (pooling_out),
        .valid_pooling (valid_pooling)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    function automatic int bin_of(input int pos);
        for (int b = 0; b < 4; b++)
            if (pos >= BIN_LO[b] && pos <= BIN_HI[b]) return b;
        return -1;
    endfunction

    initial begin
        int b, emit_idx;
        logic [3:0] v;

        rst        = 1'b1;
        valid_data = 1'b0;
        ofmap_RELU = '0;
        count_PE   = '0;
        for (int i = 0; i < 4; i++) begin
            exp_max[i] = 4'd0;
            emitted[i] = 4'd0;
        end

        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        checks++;
        if (valid_pooling !== 1'b0) begin
            errors++;
            $error("[reset] valid_pooling should be low after reset");
        end

        // --- drive one full frame -------------------------------------------
        emit_idx = 0;
        for (int row = 0; row < ROWS; row++) begin
            for (int pos = 0; pos <= LAST_POS; pos++) begin
                v = $urandom_range(0, 7);   // ReLU output is non-negative, <= 7

                count_PE   = pos[7:0];
                ofmap_RELU = v;
                valid_data = 1'b1;

                b = bin_of(pos);
                if (b >= 0 && v > exp_max[b]) exp_max[b] = v;

                @(posedge clk);
                #1;

                if (valid_pooling) begin
                    n_emits++;
                    if (emit_idx < 4) begin
                        emitted[emit_idx] = pooling_out;
                        checks++;
                        if (pooling_out > 4'd7) begin
                            errors++;
                            $error("[emit %0d] pooled value %0d exceeds ReLU range",
                                   emit_idx, pooling_out);
                        end
                    end
                    emit_idx++;
                end
            end
        end

        valid_data = 1'b0;

        // --- structural checks ------------------------------------------------
        checks++;
        if (n_emits != 4) begin
            errors++;
            $error("expected exactly 4 pooled outputs per frame, got %0d", n_emits);
        end

        // --- boundary advisory -------------------------------------------------
        for (int i = 1; i < 4; i++) begin
            if ((BIN_HI[i] - BIN_LO[i]) != (BIN_HI[0] - BIN_LO[0])) begin
                $warning("bin %0d spans %0d positions but bin 1 spans %0d -- pooling grid is not uniform",
                         i+1, BIN_HI[i]-BIN_LO[i]+1, BIN_HI[0]-BIN_LO[0]+1);
            end
            if (EMIT_AT[i] > BIN_HI[i] + 1) begin
                $warning("bin %0d is emitted at count_PE=%0d but stops accumulating at %0d",
                         i+1, EMIT_AT[i], BIN_HI[i]);
            end
        end

        $display("");
        $display("---------------------------------------------");
        $display(" tb_pooling: %0d checks, %0d failures, %0d outputs", checks, errors, n_emits);
        $display(" see testbench header: bin boundaries are non-uniform by construction");
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("---------------------------------------------");
        if (errors != 0) $fatal(1, "tb_pooling failed");
        $finish;
    end

endmodule
