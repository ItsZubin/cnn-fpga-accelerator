function [fc_out] = fully_connect(image)
    fc_filter1 = [
        2, 2, 2, 5;
        3, 4, 6, 5;
        3, 5, 3, 3;
        3, 4, 2, 2
    ];

    fc_filter2 = [
        2, -6, 2, -2
        -3, 1, -2, -5;
        0, -2, -1, -3;
        0, -2, -2, 3
    ];

    fc_filter3 = [
        0, 3, -1, -3;
        3, -8, 1, -4;
        0, -2, -6, -3;
        0, -2, 1, -3
    ];

    fc_filter4 = [-8 7 7];
    
    fc_out = zeros(1, 3);
    fc_out(1, 1) = sum(sum(image .* fc_filter1)) - 12;
    fc_out(1, 2) = sum(sum(image .* fc_filter2)) + 20;
    fc_out(1, 3) = sum(sum(image .* fc_filter3)) + 24;
    fc_out_relu = max(fc_out, 0);

    fc_out = sum(fc_out_relu .* fc_filter4) + 6;
end

