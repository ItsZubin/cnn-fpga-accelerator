module RAM_IP_TOP (
    input  logic         clk,
    input  logic [63:0]  data_1,
    input  logic [63:0]  data_2,
    input  logic [63:0]  data_3,
    input  logic [63:0]  data_4,
    input  logic [3:0]   address_1,
    input  logic [3:0]   address_2,
    input  logic [3:0]   address_3,
    input  logic [3:0]   address_4,
    input  logic         csn_1,
    input  logic         csn_2,
    input  logic         csn_3,
    input  logic         csn_4,
    input  logic         wen_1,
    input  logic         wen_2,
    input  logic         wen_3,
    input  logic         wen_4,
    input  logic [1:0]   count_def,
    output logic [63:0]  data_out_1,
    output logic [63:0]  data_out_2,
    output logic [63:0]  data_out_3,
    output logic [63:0]  data_out_4
);

    // ------------------------------------------------------------------
    // Instantiate distributed memory modules
    // ------------------------------------------------------------------
    logic [63:0] data_out_1_top, data_out_2_top, data_out_3_top, data_out_4_top;

    dist_mem_gen_0 RAM_1_inst (
        .a   (address_1),
        .d   (data_1 ),
        .clk (clk),
        .we  (wen_1),
        .spo (data_out_1_top)
    );

    dist_mem_gen_1 RAM_2_inst (
        .a   (address_2),
        .d   (data_2),
        .clk (clk),
        .we  (wen_2),
        .spo (data_out_2_top)
    );

    dist_mem_gen_2 RAM_3_inst (
        .a   (address_3),
        .d   (data_3),
        .clk (clk),
        .we  (wen_3),
        .spo (data_out_3_top)
    );

    dist_mem_gen_3 RAM_4_inst (
        .a   (address_4),
        .d   (data_4),
        .clk (clk),
        .we  (wen_4),
        .spo (data_out_4_top)
    );

    // ------------------------------------------------------------------
    // Output rotation logic based on count_def
    // ------------------------------------------------------------------
    always_comb begin
        case (count_def)
            2'd0: begin
                data_out_1 = data_out_1_top;
                data_out_2 = data_out_2_top;
                data_out_3 = data_out_3_top;
                data_out_4 = data_out_4_top;
            end

            2'd1: begin
                data_out_1 = data_out_2_top;
                data_out_2 = data_out_3_top;
                data_out_3 = data_out_4_top;
                data_out_4 = data_out_1_top;
            end

            2'd2: begin
                data_out_1 = data_out_3_top;
                data_out_2 = data_out_4_top;
                data_out_3 = data_out_1_top;
                data_out_4 = data_out_2_top;
            end

            default: begin
                data_out_1 = data_out_4_top;
                data_out_2 = data_out_1_top;
                data_out_3 = data_out_2_top;
                data_out_4 = data_out_3_top;
            end
        endcase
    end

endmodule

