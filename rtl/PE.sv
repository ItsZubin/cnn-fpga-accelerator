//module PE (
//    input  logic              clk,
//    input  logic              rst,
//    input  logic              start_pe,  
//    input  logic [63:0]       ifmap,        // 1-bit pixels
//    input  logic [5:0]        count_PE,     // slide position
//    input  logic signed [3:0] weights [0:3],// 4 signed filter weights
//    output logic signed [7:0] Psum          // final partial sum
//);
//    // Extract 4 pixels (1-bit each) based on sliding window position
//    logic [3:0] window_bits;
    
//    // Signed intermediate results
//    logic signed [7:0] mult0, mult1, mult2, mult3;
//    logic signed [9:0] acc_sum;  // Extended to 10-bit for overflow handling
    
//    // ------------------------------------------------------------------
//    // Extract bits in parallel (continuous assignment)
//    // ------------------------------------------------------------------
//    assign window_bits = (start_pe && (count_PE <= 6'd60)) ? ifmap[count_PE +: 4] : 4'b0;
    
//    // ------------------------------------------------------------------
//    // Parallel signed multiplication (pixel * weight)
//    // Since pixel is 0 or 1, it acts as an enable signal
//    // Sign-extend 4-bit weights to 8-bit for proper signed arithmetic
//    // ------------------------------------------------------------------
//    assign mult0 = window_bits[0] ? {{4{weights[0][3]}}, weights[0]} : 8'sd0;
//    assign mult1 = window_bits[1] ? {{4{weights[1][3]}}, weights[1]} : 8'sd0;
//    assign mult2 = window_bits[2] ? {{4{weights[2][3]}}, weights[2]} : 8'sd0;
//    assign mult3 = window_bits[3] ? {{4{weights[3][3]}}, weights[3]} : 8'sd0;
    
//    // ------------------------------------------------------------------
//    // Parallel signed accumulation (adder tree)
//    // ------------------------------------------------------------------
//    assign acc_sum = mult0 + mult1 + mult2 + mult3;
    
//    // ------------------------------------------------------------------
//    // Sequential output register with saturation
//    // ------------------------------------------------------------------
//    always_ff @(posedge clk or posedge rst) begin
//        if (rst) begin
//            Psum <= 8'sd0;
//        end else if (start_pe) begin
//            // Saturation to 8-bit signed range [-128, 127]
//            if (acc_sum > 10'sd127) begin
//                Psum <= 8'sd127;
//            end else if (acc_sum < -10'sd128) begin
//                Psum <= -8'sd128;
//            end else begin
//                Psum <= acc_sum[7:0];
//            end
//        end
//        // If start_pe is low, Psum holds its previous value
//    end

//endmodule


module PE (
    input  logic              clk,
    input  logic              rst,
    input  logic         start_pe,  
    input  logic [63:0]       ifmap,        // 1-bit pixels
    input  logic [7:0]        count_PE,     // slide position
    input  logic signed [3:0] weights [0:3],// 4 signed filter weights
    output logic signed  [7:0] Psum          // final partial sum
);

    // Extract 4 pixels (1-bit each) based on sliding window position
    logic [3:0] window_bits;

    // Signed intermediate results
    logic signed [7:0] mult0, mult1, mult2, mult3;
    logic signed [7:0] acc_sum;
always_comb begin
    // ------------------------------------------------------------------
    // Extract bits in parallel
    // ------------------------------------------------------------------
   // if(start_pe)begin
     window_bits =( start_pe && (count_PE <= 8'd60)) ? ifmap[count_PE +: 4] : 4'b0;

    // ------------------------------------------------------------------
    // Parallel signed multiplication (pixel * weight)
    // Since pixel is 0 or 1, it acts as an enable signal
    // ------------------------------------------------------------------
     mult0 = window_bits[0] ? weights[0] : 8'sd0;
     mult1 = window_bits[1] ? weights[1] : 8'sd0;
     mult2 = window_bits[2] ? weights[2] : 8'sd0;
     mult3 = window_bits[3] ? weights[3] : 8'sd0;

    // ------------------------------------------------------------------
    // Parallel signed accumulation (adder tree)
    // ------------------------------------------------------------------
     acc_sum = mult0 + mult1 + mult2 + mult3;
end
    // ------------------------------------------------------------------
    // Sequential output register
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            Psum <= 8'sd0;
        else
            Psum <= acc_sum;
    end
//end
endmodule