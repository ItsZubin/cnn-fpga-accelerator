module PE_TOP (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic         finish,
    input  logic  [3:0]  f_in,
    input  logic         valid_in_f,
    input  logic [63:0]  ifmap_1,
    input  logic [63:0]  ifmap_2,
    input  logic [63:0]  ifmap_3,
    input  logic [63:0]  ifmap_4,
    input  logic [7:0]   count_PE,
    output  logic signed[7:0]   Psum_1,
    output  logic signed[7:0]   Psum_2,
    output  logic signed[7:0]   Psum_3,
    output  logic signed[7:0]   Psum_4,
    output logic         start_acc
);

    // Internal registers
    logic        start_d;
    logic        start_pe;
    logic [3:0]  load_idx;
    logic [3:0]  weights [0:15];
    logic        start_acc_reg;

    // Next-state signals
    logic        next_start_d;
    logic        next_start_pe;
    logic [3:0]  next_load_idx;
    logic [3:0]  next_weights [0:15];
    logic        next_start_acc;

    // Weight arrays for each PE (4 weights per PE)
    logic signed [3:0] weights_PE1 [0:3];
    logic signed [3:0] weights_PE2 [0:3];
    logic signed [3:0] weights_PE3 [0:3];
    logic signed [3:0] weights_PE4 [0:3];

  
    // Sequential logic for register updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            start_d <= 1'b0;
            start_pe <= 1'b0;
            load_idx <= 4'd0;
            start_acc_reg <= 1'b0;
        end else begin
            start_d <= next_start_d;
            start_pe <= next_start_pe;
            load_idx <= next_load_idx;
            start_acc_reg <= next_start_acc;
        end
    end

    // Combinational logic for next states
    always_comb begin
        // Default assignments
        next_start_d = start;
        next_start_pe = start_pe;
        next_load_idx = load_idx;
        next_weights = weights;  // CRITICAL: Default to hold current values
        next_start_acc = (count_PE != 8'd0) && ~finish;

        // start_pe logic
        if (start_d && ~start)
            next_start_pe = 1'b1;
        else if (~start_d && start)
            next_start_pe = 1'b0;
        // else hold

        // Load weights logic
        if (valid_in_f) begin
            next_weights[load_idx] = f_in;
            if (load_idx < 4'd15)
                next_load_idx = load_idx + 4'd1;
        end
    end

    // Generate block for weights register updates (handles reset and updates)
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : weight_update
            always_ff @(posedge clk or posedge rst) begin
                if (rst)
                    weights[i] <= 4'd0;
                else
                    weights[i] <= next_weights[i];
            end
        end
    endgenerate

    // Generate block for distributing weights to PE arrays
    generate
        for (i = 0; i < 4; i++) begin : weight_distribute
            always_comb begin
                weights_PE1[i] = weights[i];
                weights_PE2[i] = weights[4 + i];
                weights_PE3[i] = weights[8 + i];
                weights_PE4[i] = weights[12 + i];
            end
        end
    endgenerate
    
    // Instantiate PE1
    PE PE1_inst (
        .clk      (clk),
        .rst      (rst),
        .start_pe(start_pe),
        .ifmap    (ifmap_1),
        .count_PE (count_PE),
        .weights  (weights_PE1),
        .Psum     (Psum_1)
    );
    
    // Instantiate PE2
    PE PE2_inst (
        .clk      (clk),
        .rst      (rst),
        .start_pe(start_pe),
        .ifmap    (ifmap_2),
        .count_PE (count_PE),
        .weights  (weights_PE2),
        .Psum     (Psum_2)
    );
    
    // Instantiate PE3
    PE PE3_inst (
        .clk      (clk),
        .rst      (rst),
        .start_pe(start_pe),
        .ifmap    (ifmap_3),
        .count_PE (count_PE),
        .weights  (weights_PE3),
        .Psum     (Psum_3)
    );
    
    // Instantiate PE4
    PE PE4_inst (
        .clk      (clk),
        .rst      (rst),
        .start_pe(start_pe),
        .ifmap    (ifmap_4),
        .count_PE (count_PE),
        .weights  (weights_PE4),
        .Psum     (Psum_4)
    );

    // Output assignment
    assign start_acc = start_acc_reg;

endmodule