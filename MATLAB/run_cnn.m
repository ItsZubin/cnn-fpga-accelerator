function [is_rectangle] = run_cnn(image)
    convolution_filter = [
        -3, -1,  1, -1;
         2, -2,  0,  0;
         0,  3,  0, -3;
        -1, -2, -2,  4
    ];

    convolved_image = convolve(convolution_filter, image);
    relu_activated_image = relu(convolved_image);
    max_pooled_image = max_pool(relu_activated_image);
    cnn_out = fully_connect(max_pooled_image);
    
    is_rectangle = "circle";
    if cnn_out > 0
        is_rectangle = "rectangle";
    end
end

