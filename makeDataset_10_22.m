
clear 
close all
clc


dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\*.png');
num_img = length(dir_img);
for indexImg = 18:num_img
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\' img_value '.png'];
    g = imread(img_name);
    scale=(32/size(g,1));
    gs = imresize(rgb2gray(g), scale);
    [h,w]=size(gs);
%     gs=imresize(gs(), [32 32*max(1,round(w/h))]);
    save_gBname=[img_value '-' num2str(indexImg)  '.jpg'];
  
    
end