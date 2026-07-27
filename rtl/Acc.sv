module Acc (
    input  logic                clk,
    input  logic                rst,
    input  logic                start,
    input  logic signed [7:0]   Psum1,
    input  logic signed [7:0]   Psum2,
    input  logic signed [7:0]   Psum3,
    input  logic signed [7:0]   Psum4,
    output logic        [3:0]   ofmap,
    output logic                valid_ofmap
);

    // Extract signs (MSB indicates negative in 2's complement)
    logic sign1, sign2, sign3, sign4;
    logic [7:0] mag1, mag2, mag3, mag4;
    
    // Convert 2's complement to magnitude
    always_comb begin
        // Psum1
        sign1 = Psum1[7];  // MSB is sign bit
        if (sign1) begin
            // If negative, take 2's complement to get magnitude
            mag1 = (~Psum1) + 8'd1;
        end else begin
            mag1 = Psum1;
        end
        
        // Psum2
        sign2 = Psum2[7];
        if (sign2) begin
            mag2 = (~Psum2) + 8'd1;
        end else begin
            mag2 = Psum2;
        end
        
        // Psum3
        sign3 = Psum3[7];
        if (sign3) begin
            mag3 = (~Psum3) + 8'd1;
        end else begin
            mag3 = Psum3;
        end
        
        // Psum4
        sign4 = Psum4[7];
        if (sign4) begin
            mag4 = (~Psum4) + 8'd1;
        end else begin
            mag4 = Psum4;
        end
    end
    
    // Accumulate positive and negative magnitudes separately
    logic [8:0] pos_mag;
    logic [8:0] neg_mag;
    
    always_comb begin
        pos_mag = 9'd0;
        neg_mag = 9'd0;
        
        // Accumulate based on sign
        if (!sign1) 
            pos_mag = pos_mag + mag1;
        else 
            neg_mag = neg_mag + mag1;
            
        if (!sign2) 
            pos_mag = pos_mag + mag2;
        else 
            neg_mag = neg_mag + mag2;
            
        if (!sign3) 
            pos_mag = pos_mag + mag3;
        else 
            neg_mag = neg_mag + mag3;
            
        if (!sign4) 
            pos_mag = pos_mag + mag4;
        else 
            neg_mag = neg_mag + mag4;
    end
    
    // Compute net magnitude and sign
    logic [8:0] abs_net;
    logic final_sign;
    logic [3:0] clipped_mag;
    logic [3:0] ofmap_result;
    
    always_comb begin
        // Determine net magnitude and sign
        if (pos_mag >= neg_mag) begin
            abs_net = pos_mag - neg_mag;
            final_sign = 1'b0;  // Positive
        end else begin
            abs_net = neg_mag - pos_mag;
            final_sign = 1'b1;  // Negative
        end
        
        // Clip magnitude to 4-bit range [0:15] first, then to signed range
        if (abs_net > 9'd7)
            clipped_mag = 4'd7;
        else
            clipped_mag = abs_net[3:0];
        
        // Convert to 2's complement for output
        if (final_sign && (clipped_mag != 4'd0)) begin
            // For negative: compute 2's complement
            ofmap_result = (~clipped_mag) + 4'd1;
        end else begin
            // For positive or zero
            ofmap_result = clipped_mag;
        end
    end
    
    // Register the output
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ofmap       <= 4'd0;
            valid_ofmap <= 1'b0;
        end else begin
            if (start) begin
                ofmap       <= ofmap_result;
                valid_ofmap <= 1'b1;
            end else begin
                valid_ofmap <= 1'b0;
            end
        end
    end

endmodule
//module Acc (
//    input  logic         clk,
//    input  logic         rst,
//    input  logic         start,
//    input  logic [7:0]   Psum1,
//    input  logic [7:0]   Psum2,
//    input  logic [7:0]   Psum3,
//    input  logic [7:0]   Psum4,
//    output logic [3:0]   ofmap,
//    output logic         valid_ofmap
//);

//    logic [9:0] sum;  // 10 bits to handle max sum (4 * 255 = 1020)

//    // Compute sum and saturate to 4 bits
//    always_ff @(posedge clk or posedge rst) begin
//        if (rst) begin
//            sum <= 10'd0;
//            ofmap <= 4'd0;
//            valid_ofmap <= 1'b0;
//        end else begin
//            if (start) begin
//                sum[2:0] <= Psum1[2:0] + Psum2[2:0] + Psum3[2:0] + Psum4[2:0];
//                // Saturate to 4 bits (max value 15)
//                if (sum > 10'd15) begin
//                    ofmap <= 4'hF;
//                end else begin
//                    ofmap <= sum[3:0];
//                end
//                valid_ofmap <= 1'b1;
//            end else begin
//                valid_ofmap <= 1'b0;
//            end
//        end
//    end
//endmodule
