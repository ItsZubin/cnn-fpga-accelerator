`timescale 1ns/1ps
module FC_TOP (
    input  logic        clk,
    input  logic        rst,

    // FC1 weights (48 total)
    input  logic [3:0]  kernel_FC1_in,
    input  logic        valid_FC1_in,

    // FC2 weights (3 total)
    input  logic [3:0]  kernel_FC2_in,
    input  logic        valid_FC2_in,

    // 4x4 pooled nibble stream (16 values, one per valid)
    input  logic [3:0]  pooling,
    input  logic        valid_pooling,

    // Outputs
    output logic        fc_output,
    output logic        valid_output
);

    // ============================================================
    // Storage Registers
    // ============================================================
    logic signed [3:0]  weights_FC1 [0:47];
    logic signed [3:0]  weights_FC2 [0:2];
    logic        [3:0]  pooling_buffer [0:15];

    logic [5:0]         weight_idx_FC1;
    logic [1:0]         weight_idx_FC2;
    logic [4:0]         pooling_idx;

    // Pooling capture registers
    logic        valid_pooling_q;
    logic        pool_cap_pulse;
    logic [3:0]  pooling_d;
    logic        fc1_arm;

    // FC1 registers
    logic signed [15:0] fc1_acc [0:2];
    logic        [4:0]  fc1_mult_idx;
    logic               fc1_computing, fc1_done;
    logic signed [3:0]  fc1_pre_relu [0:2];
    logic               fc1_done_q;
    logic               fc1_relu_valid;
    logic        [3:0]  fc1_out_q [0:2];
    logic               fc2_arm;

    // FC2 registers
    logic signed [15:0] fc2_acc;
    logic        [2:0]  fc2_mult_idx;
    logic               fc2_computing;

    // Output registers
    logic               fc_output_reg;
    logic               valid_output_reg;

    // ============================================================
    // Next-state signals (combinational outputs)
    // ============================================================
    logic [5:0]         weight_idx_FC1_next;
    logic [1:0]         weight_idx_FC2_next;
    logic signed [3:0]  weights_FC1_next [0:47];
    logic signed [3:0]  weights_FC2_next [0:2];
    
    logic [4:0]         pooling_idx_next;
    logic [3:0]         pooling_buffer_next [0:15];
    logic               fc1_arm_next;
    
    logic               valid_pooling_q_next;
    logic               pool_cap_pulse_next;
    logic [3:0]         pooling_d_next;
    
    logic signed [15:0] fc1_acc_next [0:2];
    logic        [4:0]  fc1_mult_idx_next;
    logic               fc1_computing_next;
    logic               fc1_done_next;
    
    logic signed [3:0]  fc1_pre_relu_next [0:2];
    logic               fc1_done_q_next;
    logic               fc1_relu_valid_next;
    
    logic        [3:0]  fc1_out_q_next [0:2];
    logic               fc2_arm_next;
    
    logic signed [15:0] fc2_acc_next;
    logic        [2:0]  fc2_mult_idx_next;
    logic               fc2_computing_next;
    
    logic               fc_output_next;
    logic               valid_output_next;

    // ReLU outputs (combinational from RELU_v1 modules)
    logic        [3:0]  fc1_relu_out [0:2];

    // ============================================================
    // Helper function
    // ============================================================
    function automatic logic signed [3:0] sat4s(input logic signed [15:0] x);
        if (x >  16'sd7)     sat4s = 4'sd7;
        else if (x < -16'sd8) sat4s = -4'sd8;
        else                 sat4s = x[3:0];
    endfunction

    // ============================================================
    // COMBINATIONAL LOGIC - All computation here
    // ============================================================
    always_comb begin
        // Default: hold current values
        weight_idx_FC1_next = weight_idx_FC1;
        weight_idx_FC2_next = weight_idx_FC2;
        weights_FC1_next = weights_FC1;
        weights_FC2_next = weights_FC2;
        
        pooling_idx_next = pooling_idx;
        pooling_buffer_next = pooling_buffer;
        fc1_arm_next = fc1_arm;  // FIXED: was defaulting to 0
        
        valid_pooling_q_next = valid_pooling;
        pool_cap_pulse_next = valid_pooling & ~valid_pooling_q;
        pooling_d_next = pooling_d;
        
        fc1_acc_next = fc1_acc;
        fc1_mult_idx_next = fc1_mult_idx;
        fc1_computing_next = fc1_computing;
        fc1_done_next = fc1_done;  // FIXED: default to current, not 0
        
        fc1_pre_relu_next = fc1_pre_relu;
        fc1_done_q_next = fc1_done;
        fc1_relu_valid_next = fc1_done_q;
        
        fc1_out_q_next = fc1_out_q;
        fc2_arm_next = fc2_arm;  // FIXED: was defaulting to 0
        
        fc2_acc_next = fc2_acc;
        fc2_mult_idx_next = fc2_mult_idx;
        fc2_computing_next = fc2_computing;
        
        fc_output_next = fc_output_reg;
        valid_output_next = valid_output_reg;

        // ========== Weight Loading Logic ==========
        if (valid_FC1_in && weight_idx_FC1 < 6'd48) begin
            weights_FC1_next[weight_idx_FC1] = kernel_FC1_in;
            weight_idx_FC1_next = weight_idx_FC1 + 6'd1;
        end
        
        if (valid_FC2_in && weight_idx_FC2 < 2'd3) begin
            weights_FC2_next[weight_idx_FC2] = kernel_FC2_in;
            weight_idx_FC2_next = weight_idx_FC2 + 2'd1;
        end

        // ========== Pooling Edge Detect Logic ==========
        if (pool_cap_pulse_next) begin
            pooling_d_next = pooling;
        end

        // ========== Pooling Capture Logic ==========
        if (pool_cap_pulse && (pooling_idx < 5'd16)) begin
            pooling_buffer_next[pooling_idx] = pooling_d;
            pooling_idx_next = pooling_idx + 5'd1;
            
            if (pooling_idx == 5'd15) begin
                fc1_arm_next = 1'b1;
            end
        end

        // ========== FC1 Start Logic ==========
        if (fc1_arm) begin
            fc1_arm_next = 1'b0;  // Clear arm signal
            fc1_computing_next = 1'b1;
            fc1_done_next = 1'b0;
            fc1_mult_idx_next = 5'd0;
            fc1_acc_next[0] = -16'sd12;  // FC1 bias
            fc1_acc_next[1] = 16'sd20;
            fc1_acc_next[2] = 16'sd24;
        end

        // ========== FC1 MAC Logic ==========
        if (fc1_computing) begin
            if (fc1_mult_idx < 5'd16) begin
                fc1_acc_next[0] = fc1_acc[0] + (signed'({1'b0, pooling_buffer[fc1_mult_idx[3:0]]}) * weights_FC1[0 + fc1_mult_idx[3:0]]);
                fc1_acc_next[1] = fc1_acc[1] + (signed'({1'b0, pooling_buffer[fc1_mult_idx[3:0]]}) * weights_FC1[16 + fc1_mult_idx[3:0]]);
                fc1_acc_next[2] = fc1_acc[2] + (signed'({1'b0, pooling_buffer[fc1_mult_idx[3:0]]}) * weights_FC1[32 + fc1_mult_idx[3:0]]);
                fc1_mult_idx_next = fc1_mult_idx + 5'd1;
            end else begin
                fc1_computing_next = 1'b0;
                fc1_done_next = 1'b1;
            end
        end else begin
            fc1_done_next = 1'b0;  // Clear done when not computing
        end

        // ========== FC1 Pre-ReLU Saturation Logic ==========
        if (fc1_done) begin
            fc1_pre_relu_next[0] = sat4s(fc1_acc[0]);
            fc1_pre_relu_next[1] = sat4s(fc1_acc[1]);
            fc1_pre_relu_next[2] = sat4s(fc1_acc[2]);
        end

        // ========== FC1 ReLU Output Latch Logic ==========
        if (fc1_relu_valid) begin
            fc1_out_q_next[0] = fc1_relu_out[0];
            fc1_out_q_next[1] = fc1_relu_out[1];
            fc1_out_q_next[2] = fc1_relu_out[2];
            fc2_arm_next = 1'b1;
        end else begin
            fc2_arm_next = 1'b0;  // Clear when not valid
        end

        // ========== FC2 Start Logic ==========
        if (fc2_arm) begin
            fc2_computing_next = 1'b1;
            fc2_mult_idx_next = 3'd0;
            fc2_acc_next = 16'sd6;  // FC2 bias
            valid_output_next = 1'b0;
        end

        // ========== FC2 MAC Logic ==========
        if (fc2_computing) begin
            if (fc2_mult_idx < 3'd3) begin
                fc2_acc_next = fc2_acc + (signed'({1'b0, fc1_out_q[fc2_mult_idx[1:0]]}) * weights_FC2[fc2_mult_idx[1:0]]);
                fc2_mult_idx_next = fc2_mult_idx + 3'd1;
            end else begin
                fc2_computing_next = 1'b0;
                
                // Decision logic
                if (fc2_acc >= 16'sd0) 
                    fc_output_next = 1'b1;
                else 
                    fc_output_next = 1'b0;
                    
                valid_output_next = 1'b1;
            end
        end

        // ========== Clear valid_output for new pooling sequence ==========
        if (pool_cap_pulse && (pooling_idx == 5'd1) && !fc1_computing) begin
            valid_output_next = 1'b0;
        end
    end

    // ============================================================
    // SEQUENTIAL LOGIC - Register updates only
    // ============================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Weight indices
            weight_idx_FC1 <= 6'd0;
            weight_idx_FC2 <= 2'd0;
            
            // Weights
            for (int i = 0; i < 48; i++) weights_FC1[i] <= 4'sd0;
            for (int i = 0; i < 3; i++) weights_FC2[i] <= 4'sd0;
            
            // Pooling
            pooling_idx <= 5'd0;
            for (int i = 0; i < 16; i++) pooling_buffer[i] <= 4'd0;
            valid_pooling_q <= 1'b0;
            pool_cap_pulse <= 1'b0;
            pooling_d <= 4'd0;
            fc1_arm <= 1'b0;
            
            // FC1
            fc1_acc[0] <= 16'd0;
            fc1_acc[1] <= 16'd0;
            fc1_acc[2] <= 16'd0;
            fc1_mult_idx <= 5'd0;
            fc1_computing <= 1'b0;
            fc1_done <= 1'b0;
            fc1_pre_relu[0] <= 4'sd0;
            fc1_pre_relu[1] <= 4'sd0;
            fc1_pre_relu[2] <= 4'sd0;
            fc1_done_q <= 1'b0;
            fc1_relu_valid <= 1'b0;
            fc1_out_q[0] <= 4'd0;
            fc1_out_q[1] <= 4'd0;
            fc1_out_q[2] <= 4'd0;
            fc2_arm <= 1'b0;
            
            // FC2
            fc2_acc <= 16'sd0;
            fc2_mult_idx <= 3'd0;
            fc2_computing <= 1'b0;
            
            // Outputs
            fc_output_reg <= 1'b0;
            valid_output_reg <= 1'b0;
        end else begin
            // Update all registers from next-state logic
            weight_idx_FC1 <= weight_idx_FC1_next;
            weight_idx_FC2 <= weight_idx_FC2_next;
            weights_FC1 <= weights_FC1_next;
            weights_FC2 <= weights_FC2_next;
            
            pooling_idx <= pooling_idx_next;
            pooling_buffer <= pooling_buffer_next;
            valid_pooling_q <= valid_pooling_q_next;
            pool_cap_pulse <= pool_cap_pulse_next;
            pooling_d <= pooling_d_next;
            fc1_arm <= fc1_arm_next;
            
            fc1_acc <= fc1_acc_next;
            fc1_mult_idx <= fc1_mult_idx_next;
            fc1_computing <= fc1_computing_next;
            fc1_done <= fc1_done_next;
            
            fc1_pre_relu <= fc1_pre_relu_next;
            fc1_done_q <= fc1_done_q_next;
            fc1_relu_valid <= fc1_relu_valid_next;
            
            fc1_out_q <= fc1_out_q_next;
            fc2_arm <= fc2_arm_next;
            
            fc2_acc <= fc2_acc_next;
            fc2_mult_idx <= fc2_mult_idx_next;
            fc2_computing <= fc2_computing_next;
            
            fc_output_reg <= fc_output_next;
            valid_output_reg <= valid_output_next;
        end
    end

    // ============================================================
    // RELU Instances (Combinational)
    // ============================================================
    RELU_v1 relu_fc1_0 (
        .ofmap_in    (fc1_pre_relu[0]),
        .valid_ofmap (fc1_relu_valid),
        .ofmap_relu  (fc1_relu_out[0])
    );
    
    RELU_v1 relu_fc1_1 (
        .ofmap_in    (fc1_pre_relu[1]),
        .valid_ofmap (fc1_relu_valid),
        .ofmap_relu  (fc1_relu_out[1])
    );
    
    RELU_v1 relu_fc1_2 (
        .ofmap_in    (fc1_pre_relu[2]),
        .valid_ofmap (fc1_relu_valid),
        .ofmap_relu  (fc1_relu_out[2])
    );

    // ============================================================
    // Output Assignment
    // ============================================================
    assign fc_output = fc_output_reg;
    assign valid_output = valid_output_reg;

endmodule