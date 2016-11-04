
clear
clc

dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 61:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    load([img_value '-fusion.mat']);
    cleanIdx=[];
    fusionBboxName=[img_value '-fusion.mat'];
    fusionBbox(cleanIdx,:)=[];
    save (fusionBboxName ,'fusionBbox' );
end