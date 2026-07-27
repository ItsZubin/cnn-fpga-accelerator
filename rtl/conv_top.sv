module conv_top (
    input  logic         clk,
    input  logic         rst,
    input  logic         start_in,
    input  logic  [3:0]  f_in,
    input  logic         valid_in_f,
    output logic  [3:0]  ofmap_relu_top,
    output logic         valid_ofmap,
  
    output logic [7:0]  count_PE
);

    // Calculation related signals
    logic [7:0]  Psum1, Psum2, Psum3, Psum4;
       logic [63:0] data_1, data_2, data_3, data_4;
    logic        finish, start_acc;
    logic [63:0] ifmap_1, ifmap_2, ifmap_3, ifmap_4;
    logic [63:0] ifmap_1_top, ifmap_2_top, ifmap_3_top, ifmap_4_top;
    logic[3:0] ofmap;
    // Memory related signals
    
    logic [3:0]  addr_1, addr_2, addr_3, addr_4;
    logic        csn_1, csn_2, csn_3, csn_4;
    logic        wen_1, wen_2, wen_3, wen_4;
    logic [1:0] count_def;

    // RELU / accumulator related signals
    logic [3:0]   ofmap_relu;
    logic        valid_ofmap_conv;

    assign valid_ofmap      = valid_ofmap_conv;
    assign ifmap_1_top      = ifmap_1;
    assign ifmap_2_top      = ifmap_2;
    assign ifmap_3_top      = ifmap_3;
    assign ifmap_4_top      = ifmap_4;
    assign ofmap_relu_top            = ofmap_relu;

    // ------------------------------------------------------------------
    // Component instantiations (named port mapping)
    // ------------------------------------------------------------------

    CONV_Controller Controller_inst (
        .clk        (clk),
        .rst        (rst),
        .start_in   (start_in),
        .address_1  (addr_1),
        .address_2  (addr_2),
        .address_3  (addr_3),
        .address_4  (addr_4),
        .csn_1      (csn_1),
        .csn_2      (csn_2),
        .csn_3      (csn_3),
        .csn_4      (csn_4),
        .wen_1      (wen_1),
        .wen_2      (wen_2),
        .wen_3      (wen_3),
        .wen_4      (wen_4),
        .finish     (finish),
        .count_def  (count_def),
        .count_PE   (count_PE)
    );

    RAM_IP_TOP RAM_inst (
        .clk         (clk),
        .data_1      (data_1),
        .data_2      (data_2),
        .data_3      (data_3),
        .data_4      (data_4),
        .address_1   (addr_1),
        .address_2   (addr_2),
        .address_3   (addr_3),
        .address_4   (addr_4),
        .csn_1       (csn_1),
        .csn_2       (csn_2),
        .csn_3       (csn_3),
        .csn_4       (csn_4),
        .wen_1       (wen_1),
        .wen_2       (wen_2),
        .wen_3       (wen_3),
        .wen_4       (wen_4),
        .count_def   (count_def),
        .data_out_1  (ifmap_1),
        .data_out_2  (ifmap_2),
        .data_out_3  (ifmap_3),
        .data_out_4  (ifmap_4)
    );


    PE_TOP PE_TOP_inst (
        .clk         (clk),
        .rst         (rst),
        .start       (start_in),
        .finish      (finish),
        .f_in        (f_in),
        .valid_in_f  (valid_in_f),
        .ifmap_1     (ifmap_1_top),
        .ifmap_2     (ifmap_2_top),
        .ifmap_3     (ifmap_3_top),
        .ifmap_4     (ifmap_4_top),
        .count_PE    (count_PE),
        .Psum_1      (Psum1),
        .Psum_2      (Psum2),
        .Psum_3      (Psum3),
        .Psum_4      (Psum4),
        .start_acc   (start_acc)
    );

    Acc Accumulator_inst (
        .clk         (clk),
        .rst         (rst),
        .start       (start_acc),
        .Psum1       (Psum1),
        .Psum2       (Psum2),
        .Psum3       (Psum3),
        .Psum4       (Psum4),
        .ofmap       (ofmap),
        .valid_ofmap (valid_ofmap_conv)
    );

    RELU_v1 RELU_inst (
        .ofmap_in    (ofmap),
        .valid_ofmap (valid_ofmap_conv),
        .ofmap_relu  (ofmap_relu)
    );
endmodule

