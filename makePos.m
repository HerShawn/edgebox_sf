clear
clc
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\*.png');
num_img = length(dir_img);
imgNeg=[];
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task3_Images\' img_value '.png'];
    g = imread(img_name);
    g=rgb2gray(g);
    g=imresize(g,[32,NaN]);
    w=size(g,2);
    
    if w<32
        g=imresize(g,[32,32]);
        w=size(g,2);
    end
    
    
    num_patch=floor(w/8)-1;
    
    if indexImg==1
        begin_patch=1;
    end
    
%     end_patch=begin_patch+num_patch-1;
    for i=1:num_patch
        imgNeg(:,:,begin_patch)= g(:,(i-1)*8+1:(i+3)*8);
        imgNeg=im2uint8(imgNeg);
        begin_patch=begin_patch+1;
    end


    imgNeg(:,:,begin_patch)=g(:,w-31:w);
    imgNeg=im2uint8(imgNeg);
    begin_patch=begin_patch+1;
end

save('imgNeg','imgNeg');

