
clear 
close all
clc
addpath(genpath('/detectorDemo'));

dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\*.png');
num_img = length(dir_img);
for indexImg = 1:num_img
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\' img_value '.png'];
    g = imread(img_name);
    %     [h,w]=size(g);
    %     g=padarray(g, [max(1,round(0.1*h)) 0], 0);
    save_gBname=[img_value '-'];
    runDetectorDemo(g,save_gBname);
    
end