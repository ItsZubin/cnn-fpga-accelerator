// ---------------------------------------------------------------------------
// Self-checking testbench for RELU_v1.
//
// RELU_v1 is purely combinational with a 4-bit input, so the input space is
// only 32 states (16 values x valid/invalid). This test is exhaustive --
// every reachable input is checked against the reference.
//
// Reference:  ofmap_relu = valid ? (ofmap_in[3] ? 0 : ofmap_in) : 0
//
// Note the interface treats ofmap_in as 4-bit signed via its MSB even though
// the port is declared unsigned; the reference mirrors that convention.
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_relu;

    logic [3:0] ofmap_in;
    logic       valid_ofmap;
    logic [3:0] ofmap_relu;

    int unsigned errors = 0;
    int unsigned checks = 0;

    RELU_v1 dut (
        .ofmap_in    (ofmap_in),
        .valid_ofmap (valid_ofmap),
        .ofmap_relu  (ofmap_relu)
    );

    function automatic logic [3:0] ref_relu(input logic [3:0] v, input logic vld);
        if (!vld)     return 4'd0;
        if (v[3])     return 4'd0;   // negative in 4-bit two's complement
        return v;
    endfunction

    initial begin
        logic [3:0] expected;

        // Exhaustive over the entire input space
        for (int vld = 0; vld <= 1; vld++) begin
            for (int v = 0; v < 16; v++) begin
                ofmap_in    = v[3:0];
                valid_ofmap = vld[0];
                #1;
                expected = ref_relu(ofmap_in, valid_ofmap);
                checks++;
                if (ofmap_relu !== expected) begin
                    errors++;
                    $error("in=%0d (signed %0d) valid=%0b : expected %0d, got %0d",
                           v, $signed(ofmap_in), valid_ofmap, expected, ofmap_relu);
                end
            end
        end

        // Property: output is never negative
        for (int v = 0; v < 16; v++) begin
            ofmap_in    = v[3:0];
            valid_ofmap = 1'b1;
            #1;
            checks++;
            if (ofmap_relu[3] !== 1'b0) begin
                errors++;
                $error("ReLU output has sign bit set for input %0d", $signed(ofmap_in));
            end
        end

        $display("");
        $display("---------------------------------------------");
        $display(" tb_relu: %0d checks, %0d failures (exhaustive)", checks, errors);
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("---------------------------------------------");
        if (errors != 0) $fatal(1, "tb_relu failed");
        $finish;
    end

endmodule
