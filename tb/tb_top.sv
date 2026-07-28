// ---------------------------------------------------------------------------
// Top-level self-checking testbench.
//
// SCOPE -- be clear about what this does and does not prove.
//
// This is a protocol and liveness test, not a numerical one. It checks that
// the accelerator comes out of reset cleanly, responds to `start`, produces a
// valid-qualified result within a bounded time, and drives no X on its
// outputs. It does NOT check that the classification result is correct,
// because the trained weights and test images (.coe files) are not part of
// this repository -- see the README.
//
// With the .coe data present, the natural next step is a golden-reference
// check: run the same quantised network in a behavioural model and compare
// the output bit. That is tracked in the README roadmap.
//
// Requires tb/dist_mem_gen_model.sv in the simulation fileset, which supplies
// behavioural stand-ins for the Xilinx distributed-RAM IP.
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_top;

    localparam int CLK_PERIOD  = 10;
    // Generous upper bound: 15 rows x 61 window positions, plus weight
    // load-in and pipeline drain, with margin.
    localparam int TIMEOUT_CYC = 200000;

    logic clk = 0;
    logic rst;
    logic start_ext;
    logic output_ext;
    logic valid_output_ext;

    int unsigned errors  = 0;
    int unsigned checks  = 0;
    int unsigned n_valid = 0;
    int          cycles  = 0;
    int          first_valid_cycle = -1;

    top dut (
        .clk              (clk),
        .rst              (rst),
        .start_ext        (start_ext),
        .output_ext       (output_ext),
        .valid_output_ext (valid_output_ext)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    always @(posedge clk) if (!rst) cycles++;

    // --- continuous checks --------------------------------------------------
    // Outputs must never be X or Z once reset is released.
    always @(posedge clk) begin
        if (!rst) begin
            if (valid_output_ext === 1'bx || valid_output_ext === 1'bz) begin
                errors++;
                $error("[cycle %0d] valid_output_ext is X/Z", cycles);
            end
            if (valid_output_ext === 1'b1 &&
                (output_ext === 1'bx || output_ext === 1'bz)) begin
                errors++;
                $error("[cycle %0d] output_ext is X/Z while valid is asserted", cycles);
            end
        end
    end

    // Count result beats
    always @(posedge clk) begin
        if (!rst && valid_output_ext === 1'b1) begin
            n_valid++;
            if (first_valid_cycle < 0) first_valid_cycle = cycles;
        end
    end

    initial begin
        // --- reset ------------------------------------------------------------
        rst       = 1'b1;
        start_ext = 1'b0;
        repeat (10) @(posedge clk);

        checks++;
        if (valid_output_ext !== 1'b0) begin
            errors++;
            $error("[reset] valid_output_ext must be low during reset, got %0b",
                   valid_output_ext);
        end

        @(posedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);

        checks++;
        if (valid_output_ext !== 1'b0) begin
            errors++;
            $error("[idle] valid_output_ext asserted before start was issued");
        end

        // --- start pulse --------------------------------------------------------
        @(posedge clk);
        start_ext = 1'b1;
        repeat (10) @(posedge clk);
        start_ext = 1'b0;

        // --- wait for a result, with timeout -------------------------------------
        fork
            begin : wait_valid
                wait (valid_output_ext === 1'b1);
            end
            begin : timeout_watchdog
                repeat (TIMEOUT_CYC) @(posedge clk);
                errors++;
                $error("TIMEOUT: no valid output within %0d cycles of start",
                       TIMEOUT_CYC);
            end
        join_any
        disable fork;

        // --- let the pipeline drain ----------------------------------------------
        repeat (2000) @(posedge clk);

        checks++;
        if (n_valid == 0) begin
            errors++;
            $error("design never asserted valid_output_ext");
        end else begin
            $display("note: first valid output at cycle %0d after reset release",
                     first_valid_cycle);
        end

        $display("");
        $display("---------------------------------------------");
        $display(" tb_top: %0d checks, %0d failures", checks, errors);
        $display(" result beats observed: %0d", n_valid);
        $display(" scope: protocol/liveness only -- output value NOT checked");
        $display("        (requires .coe data, see README)");
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("---------------------------------------------");
        if (errors != 0) $fatal(1, "tb_top failed");
        $finish;
    end

endmodule
