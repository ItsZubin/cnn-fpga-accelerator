module top (
    input  logic       clk,
    input  logic       rst,
    input  logic       start_ext,
    output logic       output_ext,
    output logic       valid_output_ext
);

    // ------------------------------------------------------------------
    // FSM for start signal pulse generation
    // ------------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, COUNTER, FINISH} start_state_t;
    start_state_t curr_state_start, next_state_start;

    // ------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------
    logic [3:0] filter;
    logic [3:0] kernel_FC1, kernel_FC2;
    logic valid_data_k_FC1, valid_data_k_FC2, valid_data_f;
    logic start_read, start_ext_sig;

    logic valid_output_sig, valid_output_sig_d, valid_output_sig_q;
    logic output_sig, output_sig_d, output_sig_q;

    logic [23:0] counter_d, counter_q;

    // ------------------------------------------------------------------
    // Sequential process: state & registers
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state_start   <= IDLE;
            counter_q          <= '0;
            valid_output_sig_q <= 1'b0;
            output_sig_q       <= '0;
        end else begin
            curr_state_start   <= next_state_start;
            counter_q          <= counter_d;
            valid_output_sig_q <= valid_output_sig_d;
            output_sig_q       <= output_sig_d;
        end
    end

    // ------------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------------
    network_top network_inst (
        .clk            (clk),
        .rst            (rst),
        .start_in       (start_read),
        .f_in           (filter),
        .valid_in_f     (valid_data_f),
        .k_FC1_in       (kernel_FC1),
        .valid_k_FC1_in (valid_data_k_FC1),
        .k_FC2_in       (kernel_FC2),
        .valid_k_FC2_in (valid_data_k_FC2),
        .out            (output_sig),
        .valid_output   (valid_output_sig)
    );

    top_initialize initialize_inst (
        .clk            (clk),
        .rst            (rst),
        .start_in       (start_ext_sig),
        .f_in           (filter),
        .valid_in_f     (valid_data_f),
        .k_FC1_in       (kernel_FC1),
        .valid_k_FC1_in (valid_data_k_FC1),
        .k_FC2_in       (kernel_FC2),
        .valid_k_FC2_in (valid_data_k_FC2),
        .start_read     (start_read)
    );

    // ------------------------------------------------------------------
    // FSM for start_ext_sig (one-cycle pulse)
    // ------------------------------------------------------------------
    always_comb begin
        next_state_start = curr_state_start;
        start_ext_sig    = 1'b0;

        case (curr_state_start)
            IDLE: begin
                if (start_ext)
                    next_state_start = COUNTER;
            end

            COUNTER: begin
                start_ext_sig    = 1'b1;
                next_state_start = FINISH;
            end

            default: begin
                start_ext_sig    = 1'b0;
                next_state_start = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // Output latch (holds values until new valid_output comes)
    // ------------------------------------------------------------------
    always_comb begin
        if (valid_output_sig) begin
            valid_output_sig_d = valid_output_sig;
            output_sig_d       = output_sig;
        end else begin
            valid_output_sig_d = valid_output_sig_q;
            output_sig_d       = output_sig_q;
        end
    end

    // ------------------------------------------------------------------
    // Output assignments
    // ------------------------------------------------------------------
    assign output_ext       = output_sig_q;
    assign valid_output_ext = valid_output_sig_q;

endmodule

