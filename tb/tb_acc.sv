// ---------------------------------------------------------------------------
// Self-checking testbench for Acc.
//
// Acc sums four signed 8-bit partial sums and clips the result into 4-bit
// signed range. The RTL does this the long way round -- splitting each input
// into sign and magnitude, accumulating positive and negative magnitudes
// separately, then differencing them. The reference model here deliberately
// does NOT mirror that structure; it computes the arithmetically obvious
// answer, so the test is an independent check rather than a restatement of
// the implementation.
//
//   reference:  net = P1 + P2 + P3 + P4          (exact signed sum)
//               out = clamp(net, -7, +7)          in 4-bit two's complement
//
// Input range
// -----------
// The randomised test drives the range the PEs can actually produce,
// [-32, +28]. The full port range is exercised separately: note that the
// RTL's magnitude accumulators are 9 bits, so four inputs at -128 would sum
// to 512 and overflow. That is unreachable in this design (PE output is
// bounded by construction) but it is a latent limit of the module in
// isolation, so it is reported as a warning rather than a failure.
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_acc;

    localparam int CLK_PERIOD = 10;
    localparam int N_RANDOM   = 4000;

    // Bounds on what a PE can emit: four weights in [-8,+7]
    localparam int PE_MIN = -32;
    localparam int PE_MAX =  28;

    logic              clk = 0;
    logic              rst;
    logic              start;
    logic signed [7:0] Psum1, Psum2, Psum3, Psum4;
    logic [3:0]        ofmap;
    logic              valid_ofmap;

    int unsigned errors   = 0;
    int unsigned checks   = 0;
    int unsigned warnings = 0;

    Acc dut (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .Psum1       (Psum1),
        .Psum2       (Psum2),
        .Psum3       (Psum3),
        .Psum4       (Psum4),
        .ofmap       (ofmap),
        .valid_ofmap (valid_ofmap)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // --- reference model ---------------------------------------------------
    function automatic logic [3:0] ref_acc(input int net);
        int clamped;
        clamped = net;
        if (clamped >  7) clamped =  7;
        if (clamped < -7) clamped = -7;
        return clamped[3:0];   // two's complement, 4-bit
    endfunction

    task automatic drive_and_check(input int p1, p2, p3, p4,
                                   input logic i_start,
                                   input string tag,
                                   input bit strict);
        int  net;
        logic [3:0] expected;
        logic       expected_valid;

        Psum1 = p1[7:0];
        Psum2 = p2[7:0];
        Psum3 = p3[7:0];
        Psum4 = p4[7:0];
        start = i_start;

        net            = p1 + p2 + p3 + p4;
        expected       = ref_acc(net);
        expected_valid = i_start;

        @(posedge clk);
        #1;
        checks++;

        if (valid_ofmap !== expected_valid) begin
            errors++;
            $error("[%s] valid_ofmap: expected %0b, got %0b",
                   tag, expected_valid, valid_ofmap);
        end

        if (i_start) begin
            if (ofmap !== expected) begin
                if (strict) begin
                    errors++;
                    $error("[%s] sum=%0d : expected ofmap=%0d (0b%04b), got %0d (0b%04b)",
                           tag, net, $signed(expected), expected,
                           $signed(ofmap), ofmap);
                end else begin
                    warnings++;
                    $warning("[%s] sum=%0d : expected %0d, got %0d (outside design-reachable range)",
                             tag, net, $signed(expected), $signed(ofmap));
                end
            end
        end
    endtask

    initial begin
        rst   = 1'b1;
        start = 1'b0;
        Psum1 = '0; Psum2 = '0; Psum3 = '0; Psum4 = '0;

        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk); #1;

        checks++;
        if (ofmap !== 4'd0 || valid_ofmap !== 1'b0) begin
            errors++;
            $error("[reset] expected ofmap=0 valid=0, got ofmap=%0d valid=%0b",
                   ofmap, valid_ofmap);
        end

        // --- directed: clipping boundaries ----------------------------------
        drive_and_check(  0,   0,   0,   0, 1'b1, "zero",          1);
        drive_and_check(  7,   0,   0,   0, 1'b1, "exact-pos-max", 1);
        drive_and_check( -7,   0,   0,   0, 1'b1, "exact-neg-max", 1);
        drive_and_check(  8,   0,   0,   0, 1'b1, "clip-pos",      1);
        drive_and_check( -8,   0,   0,   0, 1'b1, "clip-neg",      1);
        drive_and_check( 28,   0,   0,   0, 1'b1, "pe-max",        1);
        drive_and_check(-32,   0,   0,   0, 1'b1, "pe-min",        1);

        // --- directed: cancellation -----------------------------------------
        drive_and_check(  7,  -7,   0,   0, 1'b1, "cancel-a",      1);
        drive_and_check(-20,  20,   0,   0, 1'b1, "cancel-b",      1);
        drive_and_check( 15, -10,  -5,   0, 1'b1, "cancel-c",      1);

        // --- directed: start low must deassert valid -------------------------
        drive_and_check(  7,   7,   7,   7, 1'b0, "start-low",     1);

        // --- randomised over the design-reachable range ----------------------
        for (int n = 0; n < N_RANDOM; n++) begin
            drive_and_check($urandom_range(PE_MIN, PE_MAX),
                            $urandom_range(PE_MIN, PE_MAX),
                            $urandom_range(PE_MIN, PE_MAX),
                            $urandom_range(PE_MIN, PE_MAX),
                            $urandom_range(0, 1),
                            $sformatf("random-%0d", n),
                            1);
        end

        // --- full port range: reported, not enforced -------------------------
        // Documents the 9-bit magnitude-accumulator limit noted in the header.
        for (int n = 0; n < 200; n++) begin
            drive_and_check($urandom_range(-128, 127),
                            $urandom_range(-128, 127),
                            $urandom_range(-128, 127),
                            $urandom_range(-128, 127),
                            1'b1,
                            $sformatf("extreme-%0d", n),
                            0);
        end

        $display("");
        $display("---------------------------------------------");
        $display(" tb_acc: %0d checks, %0d failures, %0d warnings", checks, errors, warnings);
        if (warnings != 0)
            $display(" note: warnings are full-port-range cases unreachable in this design");
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("---------------------------------------------");
        if (errors != 0) $fatal(1, "tb_acc failed");
        $finish;
    end

endmodule
