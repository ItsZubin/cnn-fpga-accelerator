module RELU_v1 (
    input  logic [3:0]  ofmap_in,
    input  logic        valid_ofmap,
    output logic [3:0]  ofmap_relu
);

    // ReLU activation: f(x) = max(0, x)
    // For 4-bit signed input, MSB is sign bit
    // If MSB=1 (negative), output 0
    // If MSB=0 (positive), output input value
    
    always_comb begin
        if (valid_ofmap) begin
            // Check if input is negative (MSB = 1)
            if (ofmap_in[3]) begin
                ofmap_relu = 4'b0000;
            end else begin
                ofmap_relu = ofmap_in;
            end
        end else begin
            ofmap_relu = 4'b0000;
        end
    end

endmodule