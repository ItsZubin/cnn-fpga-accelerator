clear all;
clc;

file = 'Images/imgTst/img_00019.png';

BW = imread(file);
fid = fopen('mem_init_data.coe','wt');

fprintf(fid,'memory_initialization_radix = 2;\n');
fprintf(fid,'memory_initialization_vector =\n');
for ii = 1:size(BW,1)-1
    fprintf(fid,'%g',BW(ii,:));
    fprintf(fid,',\n');
end
fprintf(fid,'%g',BW(size(BW,1),:));
fprintf(fid,';\n');
fclose(fid);

