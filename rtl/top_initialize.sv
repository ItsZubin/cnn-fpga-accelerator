module top_initialize (
    input  logic        clk,
    input  logic        rst,
    input  logic        start_in,
    output logic [3:0]  f_in,
    output logic        valid_in_f,
    output logic [3:0]  k_FC1_in,
    output logic        valid_k_FC1_in,
    output logic [3:0]  k_FC2_in,
    output logic        valid_k_FC2_in,
    output logic        start_read
);

    // ------------------------------------------------------------------
    // FSM state definitions
    // ------------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, COUNTER, FINISH} state_t;

    state_t curr_state_fin,  next_state_fin;
    state_t curr_state_fc1,  next_state_fc1;
    state_t curr_state_fc2,  next_state_fc2;
    state_t curr_state_read, next_state_read;

    // ------------------------------------------------------------------
    // Counters
    // ------------------------------------------------------------------
    logic [5:0] count_fin,        next_count_fin;
    logic [5:0] count_fc1,        next_count_fc1;
    logic [5:0] count_fc2,        next_count_fc2;
    logic [6:0] count_start_read, next_count_start_read;

    // ------------------------------------------------------------------
    // ROMs (constant initialized arrays)
    // ------------------------------------------------------------------
    logic [3:0] rom_mem_fin [0:15] = '{
        4'b1101, 4'b1111, 4'b0001, 4'b1111,
        4'b0010, 4'b1110, 4'b0000, 4'b0000,
        4'b0000, 4'b0011, 4'b0000, 4'b1101,
        4'b1111, 4'b1110, 4'b1110, 4'b0100
    };

    logic [3:0] rom_mem_fc1 [0:47] = '{
        4'b0010,4'b0010,4'b0010,4'b0101,4'b0011,4'b0100,
        4'b0110,4'b0101,4'b0011,4'b0101,4'b0011,4'b0011,
        4'b0011,4'b0100,4'b0010,4'b0010,4'b0010,4'b1010,
        4'b0010,4'b1110,4'b1101,4'b0001,4'b1110,4'b1011,
        4'b0000,4'b1110,4'b1111,4'b1101,4'b0000,4'b1110,
        4'b1110,4'b0011,4'b0000,4'b0011,4'b1111,4'b1101,
        4'b0011,4'b1000,4'b0001,4'b1100,4'b0000,4'b1110,
        4'b1010,4'b1101,4'b0000,4'b1110,4'b0001,4'b1101
    };

    logic [3:0] rom_mem_fc2 [0:2] = '{
        4'b1000, 4'b0111, 4'b0111
    };

    // ------------------------------------------------------------------
    // Sequential state/counter update
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state_fin   <= IDLE;
            curr_state_fc1   <= IDLE;
            curr_state_fc2   <= IDLE;
            curr_state_read  <= IDLE;
            count_fin        <= '0;
            count_fc1        <= '0;
            count_fc2        <= '0;
            count_start_read <= '0;
        end else begin
            curr_state_fin   <= next_state_fin;
            curr_state_fc1   <= next_state_fc1;
            curr_state_fc2   <= next_state_fc2;
            curr_state_read  <= next_state_read;
            count_fin        <= next_count_fin;
            count_fc1        <= next_count_fc1;
            count_fc2        <= next_count_fc2;
            count_start_read <= next_count_start_read;
        end
    end

    // ------------------------------------------------------------------
    // ROM outputs (combinational reads)
    // ------------------------------------------------------------------
    assign f_in      = rom_mem_fin[count_fin];
    assign k_FC1_in  = rom_mem_fc1[count_fc1];
    assign k_FC2_in  = rom_mem_fc2[count_fc2];

    // ------------------------------------------------------------------
    // FSM: Writing_F_in
    // ------------------------------------------------------------------
    always_comb begin
        next_state_fin   = curr_state_fin;
        next_count_fin   = '0;
        valid_in_f       = 1'b0;

        case (curr_state_fin)
            IDLE: begin
                if (start_in)
                    next_state_fin = COUNTER;
            end

            COUNTER: begin
                valid_in_f = 1'b1;
                if (count_fin == 6'd15) begin
                    next_count_fin = '0;
                    next_state_fin = FINISH;
                end else begin
                    next_count_fin = count_fin + 1;
                    next_state_fin = COUNTER;
                end
            end

            FINISH: begin
                valid_in_f     = 1'b0;
                next_state_fin = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // FSM: writing_FC1
    // ------------------------------------------------------------------
    always_comb begin
        next_state_fc1   = curr_state_fc1;
        next_count_fc1   = '0;
        valid_k_FC1_in   = 1'b0;

        case (curr_state_fc1)
            IDLE: begin
                if (start_in)
                    next_state_fc1 = COUNTER;
            end

            COUNTER: begin
                valid_k_FC1_in = 1'b1;
                if (count_fc1 == 6'd47) begin
                    next_count_fc1 = '0;
                    next_state_fc1 = IDLE;
                end else begin
                    next_count_fc1 = count_fc1 + 1;
                    next_state_fc1 = COUNTER;
                end
            end

            FINISH: begin
                valid_k_FC1_in = 1'b0;
                next_state_fc1 = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // FSM: writing_FC2
    // ------------------------------------------------------------------
    always_comb begin
        next_state_fc2   = curr_state_fc2;
        next_count_fc2   = '0;
        valid_k_FC2_in   = 1'b0;

        case (curr_state_fc2)
            IDLE: begin
                if (start_in)
                    next_state_fc2 = COUNTER;
            end

            COUNTER: begin
                valid_k_FC2_in = 1'b1;
                if (count_fc2 == 6'd2) begin
                    next_count_fc2 = '0;
                    next_state_fc2 = IDLE;
                end else begin
                    next_count_fc2 = count_fc2 + 1;
                    next_state_fc2 = COUNTER;
                end
            end

            FINISH: begin
                valid_k_FC2_in = 1'b0;
                next_state_fc2 = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // FSM: start_memory_reading
    // ------------------------------------------------------------------
    always_comb begin
        next_state_read       = curr_state_read;
        next_count_start_read = '0;
        start_read            = 1'b0;

        case (curr_state_read)
            IDLE: begin
                if (start_in)
                    next_state_read = COUNTER;
            end
        default: begin
                if (count_start_read == 7'd100) begin
                    next_count_start_read = '0;
                    next_state_read       = IDLE;
                    start_read            = 1'b1;
                end else begin
                    next_count_start_read = count_start_read + 1;
                    next_state_read       = COUNTER;
                    start_read            = 1'b0;
                end
            end
        endcase
    end

endmodule


