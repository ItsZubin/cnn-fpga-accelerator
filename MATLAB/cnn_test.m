clear all;
clc;


NUM_IMAGES_TO_TEST = 50;


for i = 1:NUM_IMAGES_TO_TEST
    image_file_name = ['Images/imgTst/img_0', num2str(i, '%04d'), '.png'];
    image = imread(image_file_name);
    shape = run_cnn(image);
    fprintf([image_file_name, ' is a %s\n'], shape);
end


