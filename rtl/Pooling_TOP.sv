`timescale 1ns/1ps
module Pooling_TOP (
    input  logic        clk,
    input  logic        rst,
    input  logic [3:0]  ofmap_RELU,
    input  logic        valid_data,
    
    input  logic [7:0]  count_PE,
    output logic [3:0]  pooling_out,
    output logic        valid_pooling
);

    // Internal registers
    logic [3:0] reg1_max;
    logic [3:0] reg2_max;
    logic [3:0] reg3_max;
    logic [3:0] reg4_max;
    logic [3:0] row_counter;
    logic [7:0] last_count_PE;
    logic [3:0] pooling_out_reg;
    logic       valid_pooling_reg;

    // Next-state signals
    logic [3:0] next_reg1_max;
    logic [3:0] next_reg2_max;
    logic [3:0] next_reg3_max;
    logic [3:0] next_reg4_max;
    logic [3:0] next_row_counter;
    logic [7:0] next_last_count_PE;
    logic [3:0] next_pooling_out;
    logic       next_valid_pooling;
logic [3:0] updated_reg1_max;
    logic [3:0] updated_reg2_max;
    logic [3:0] updated_reg3_max;
    logic [3:0] updated_reg4_max;
    // Combinational logic
    logic new_row;
    assign new_row = (last_count_PE == 8'd60) && (count_PE == 8'd0);

    always_comb begin
        // Defaults
        next_last_count_PE = count_PE;
        next_row_counter = row_counter;
        next_reg1_max = reg1_max;
        next_reg2_max = reg2_max;
        next_reg3_max = reg3_max;
        next_reg4_max = reg4_max;
        next_pooling_out = pooling_out_reg;
        next_valid_pooling = 1'b0;
updated_reg1_max = reg1_max;
        updated_reg2_max = reg2_max;
        updated_reg3_max = reg3_max;
        updated_reg4_max = reg4_max;
        // Row counter update
        if (new_row) begin
            if (row_counter == 4'd14)
                next_row_counter = 4'd0;
            else
                next_row_counter = row_counter + 4'd1;
        end

        // Compute updated max values


        if (new_row && (row_counter == 4'd14)) begin
            next_reg1_max = 4'd0;
            next_reg2_max = 4'd0;
            next_reg3_max = 4'd0;
            next_reg4_max = 4'd0;
        end else if (valid_data) begin
            if (count_PE >= 8'd0 && count_PE <= 8'd15) begin
                updated_reg1_max = (ofmap_RELU > reg1_max) ? ofmap_RELU : reg1_max;
            end else if (count_PE >= 8'd16 && count_PE <= 8'd30) begin
                updated_reg2_max = (ofmap_RELU > reg2_max) ? ofmap_RELU : reg2_max;
            end else if (count_PE >= 8'd31 && count_PE <= 8'd45) begin
                updated_reg3_max = (ofmap_RELU > reg3_max) ? ofmap_RELU : reg3_max;
            end else if (count_PE >= 8'd45 && count_PE < 8'd61) begin
                updated_reg4_max = (ofmap_RELU > reg4_max) ? ofmap_RELU : reg4_max;
            end
            // Apply updated to next
            next_reg1_max = updated_reg1_max;
            next_reg2_max = updated_reg2_max;
            next_reg3_max = updated_reg3_max;
            next_reg4_max = updated_reg4_max;
        end

        // Output and individual reset logic
        if (row_counter == 4'd14 && valid_data) begin
            if (count_PE == 8'd16) begin
                next_pooling_out = updated_reg1_max;
                next_valid_pooling = 1'b1;
                next_reg1_max = 4'd0;
            end else if (count_PE == 8'd32) begin
                next_pooling_out = updated_reg2_max;
                next_valid_pooling = 1'b1;
                next_reg2_max = 4'd0;
            end else if (count_PE == 8'd48) begin
                next_pooling_out = updated_reg3_max;
                next_valid_pooling = 1'b1;
                next_reg3_max = 4'd0;
            end else if (count_PE == 8'd60) begin
                next_pooling_out = updated_reg4_max;
                next_valid_pooling = 1'b1;
                next_reg4_max = 4'd0;
            end
        end
    end

    // Sequential updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg1_max <= 4'd0;
            reg2_max <= 4'd0;
            reg3_max <= 4'd0;
            reg4_max <= 4'd0;
            row_counter <= 4'd0;
            last_count_PE <= 8'd0;
            pooling_out_reg <= 4'd0;
            valid_pooling_reg <= 1'b0;
        end else begin
            reg1_max <= next_reg1_max;
            reg2_max <= next_reg2_max;
            reg3_max <= next_reg3_max;
            reg4_max <= next_reg4_max;
            row_counter <= next_row_counter;
            last_count_PE <= next_last_count_PE;
            pooling_out_reg <= next_pooling_out;
            valid_pooling_reg <= next_valid_pooling;
        end
    end

    // Output assignments
    assign pooling_out = pooling_out_reg;
    assign valid_pooling = valid_pooling_reg;

endmodule
