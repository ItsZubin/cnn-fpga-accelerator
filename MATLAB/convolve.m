function [convolved_image] = convolve(filter ,image)
    convolved_image = xcorr2(filter, image);
    convolved_image = convolved_image(4:64, 4:64);
end

