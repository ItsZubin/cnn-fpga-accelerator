module CONV_Controller (
    input  logic         clk,
    input  logic         rst,
    input  logic         start_in,

    // RAM address outputs (4 bits because Depth=16)
    output logic [3:0]   address_1,
    output logic [3:0]   address_2,
    output logic [3:0]   address_3,
    output logic [3:0]   address_4,

    // chip select (active low) and write enable (polarity depends on your IP)
    output logic         csn_1,
    output logic         csn_2,
    output logic         csn_3,
    output logic         csn_4,

    output logic         wen_1,
    output logic         wen_2,
    output logic         wen_3,
    output logic         wen_4,

    // status outputs
    output logic         finish,      // asserted when all windows processed
    output logic [1:0]   count_def,   // phase counter (0..3)
    output logic [7:0]   count_PE     // 8-bit view of processed windows (lower 8 bits)
);

    // Internal registers
    logic active;
    logic [5:0] v_pos;  // Vertical position counter (0 to 60 for 61 positions)
    logic [5:0] h_pos;  // Horizontal position counter (0 to 60 for 61 positions)
    logic [3:0] addr_1_reg;
    logic [3:0] addr_2_reg;
    logic [3:0] addr_3_reg;
    logic [3:0] addr_4_reg;
    logic finish_reg;

    // Next-state signals
    logic next_active;
    logic [5:0] next_v_pos;
    logic [5:0] next_h_pos;
    logic [3:0] next_addr_1;
    logic [3:0] next_addr_2;
    logic [3:0] next_addr_3;
    logic [3:0] next_addr_4;
    logic next_finish;

    // Combinational logic for next states
    always_comb begin
        next_active = active;
        next_v_pos = v_pos;
        next_h_pos = h_pos;
        next_addr_1 = addr_1_reg;
        next_addr_2 = addr_2_reg;
        next_addr_3 = addr_3_reg;
        next_addr_4 = addr_4_reg;
        next_finish = finish_reg;

        if (!active) begin
            if (start_in) begin
                next_active = 1'b1;
                next_v_pos = 6'd0;
                next_h_pos = 6'd0;
                next_finish = 1'b0;
            end
        end else begin
            if (h_pos == 6'd60) begin
                if (v_pos == 6'd60) begin
                    next_active = 1'b0;
                    next_finish = 1'b1;
                end else begin
                    next_h_pos = 6'd0;
                    next_v_pos = v_pos + 6'd1;
                end
                // Address increment based on current v_pos
                case (v_pos[1:0])
                    2'd0: next_addr_1 = addr_1_reg + 4'd1;
                    2'd1: next_addr_2 = addr_2_reg + 4'd1;
                    2'd2: next_addr_3 = addr_3_reg + 4'd1;
                    2'd3: next_addr_4 = addr_4_reg + 4'd1;
                endcase
            end else begin
                next_h_pos = h_pos + 6'd1;
            end
        end
    end

    // Sequential logic for register updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            active <= 1'b0;
            v_pos <= 6'd0;
            h_pos <= 6'd0;
            addr_1_reg <= 4'd0;
            addr_2_reg <= 4'd0;
            addr_3_reg <= 4'd0;
            addr_4_reg <= 4'd0;
            finish_reg <= 1'b0;
        end else begin
            active <= next_active;
            v_pos <= next_v_pos;
            h_pos <= next_h_pos;
            addr_1_reg <= next_addr_1;
            addr_2_reg <= next_addr_2;
            addr_3_reg <= next_addr_3;
            addr_4_reg <= next_addr_4;
            finish_reg <= next_finish;
        end
    end

    // Derived signals and constant assignments
    assign address_1 = addr_1_reg;
    assign address_2 = addr_2_reg;
    assign address_3 = addr_3_reg;
    assign address_4 = addr_4_reg;
    assign finish = finish_reg;
    assign count_def = v_pos[1:0];  // (s-1) % 4 where s = v_pos + 1
    assign count_PE = {2'b00, h_pos};  // Extend to 8 bits

    // Always read mode
    assign csn_1 = 1'b0;
    assign csn_2 = 1'b0;
    assign csn_3 = 1'b0;
    assign csn_4 = 1'b0;

    // No writes
    assign wen_1 = 1'b0;
    assign wen_2 = 1'b0;
    assign wen_3 = 1'b0;
    assign wen_4 = 1'b0;

endmodule