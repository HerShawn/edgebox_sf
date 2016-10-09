clc; clear ; close all;
% I = imread('c:\\pic\\图片1.bmp');
% figure; hold on;
% h1 = axes('position', [0.0 0.0 1.0 1.0], 'parent', gcf);;
% imshow(I, 'parent', h1);
% h2 = axes('position', [0.2 0.2 0.5 0.5], 'parent', gcf);
% axes(h2);
% I1 = imread('rice.png');
% imshow(I1, 'parent', h2);

ground_dir_img=dir('C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\ground\images\*.bmp');
text_dir_img=dir('C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\*.bmp');

num_img=length(text_dir_img);

for indexImg = 1:6:num_img
    
    groundIdx=round(indexImg/6)+1;
    ground_value = ground_dir_img(groundIdx).name;
    ground_value = ground_value(1:end-4);
    ground_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\ground\images\' ground_value '.bmp'];
    ground = imread(ground_name);
    
    [len,wid,~]=size(ground);
    gt=im2uint8(zeros(len,wid));
    
    
    %word1,左上
    word1_value = text_dir_img(indexImg).name;
    word1_value = word1_value(1:end-4);
    word1_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word1_value '.bmp'];
    word1=imread(word1_name);
    [len1,wid1,~]=size(word1);
    if len1/wid1<1
        word1=imresize(word1,[NaN,48]);
        [len1,wid1,~]=size(word1);
        gt(48:(len1+47), 48:95) =  word1;
    else
        word1=imresize(word1,[32,NaN]);
        [len1,wid1,~]=size(word1);
        gt(48:79, 48:wid1+47) =  word1;
    end
    
    
    %word2,左下
    word2_value = text_dir_img(indexImg+1).name;
    word2_value = word2_value(1:end-4);
    word2_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word2_value '.bmp'];
    word2=imread(word2_name);
    
    [len2,wid2,~]=size(word2);
    if len2/wid2<1
        word2=imresize(word2,[NaN,48]);
        [len2,wid2,~]=size(word2);
        gt(end-96:end-97+len2, 48:95) = word2;
    else
        word2=imresize(word2,[32,NaN]);
        [len2,wid2,~]=size(word2);
        gt(end-96:end-65, 48:wid2+47) =word2;
    end
    
    %word3,右上
    word3_value = text_dir_img(indexImg+2).name;
    word3_value = word3_value(1:end-4);
    word3_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word3_value '.bmp'];
    word3=imread(word3_name);
    
    [len3,wid3,~]=size(word3);
    if len3/wid3<1
        
        word3=imresize(word3,[NaN,48]);
        [len3,wid3,~]=size(word3);
        gt(48:(len3+47), end-96:end-49) = word3;
    else
        word3=imresize(word3,[32,NaN]);
        [len3,wid3,~]=size(word3);
        gt(48:79, end-96:end+wid3-97) = word3;
    end
    
    %word4,右下
    word4_value = text_dir_img(indexImg+3).name;
    word4_value = word4_value(1:end-4);
    word4_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word4_value '.bmp'];
    word4=imread(word4_name);
    [len4,wid4,~]=size(word4);
    
    if len4/wid4<1
        word4=imresize(word4,[NaN,48]);
        [len4,wid4,~]=size(word4);
        gt(end-96:end-97+len4, end-96:end-49) =word4;
    else
        word4=imresize(word4,[32,NaN]);
        [len4,wid4,~]=size(word4);
        gt(end-96:end-65, end-96:end+wid4-97) =word4 ;
    end
    
    %word5,中上
    word5_value = text_dir_img(indexImg+4).name;
    word5_value = word5_value(1:end-4);
    word5_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word5_value '.bmp'];
    word5=imread(word5_name);
    [len5,wid5,~]=size(word5);
    if len5/wid5<1
        word5=imresize(word5,[NaN,48]);
        [len5,wid5,~]=size(word5);
        gt(round(len/2)-72:round(len/2)-73+len5,round(wid/2)-72:round(wid/2)-25) =word5;
    else
        word5=imresize(word5,[32,NaN]);
        [len5,wid5,~]=size(word5);
        gt(round(len/2)-72:round(len/2)-41,round(wid/2)-72:round(wid/2)-73+wid5) =word5;
    end
    
    %word6,中下
    word6_value = text_dir_img(indexImg+5).name;
    word6_value = word6_value(1:end-4);
    word6_name = ['C:\Users\Administrator\Desktop\制作数据集\2016-10-1数据集\text\groundTruth\' word6_value '.bmp'];
    word6=imread(word6_name);
    [len6,wid6,~]=size(word6);
    if len6/wid6<1
        word6=imresize(word6,[NaN,48]);
        [len6,wid6,~]=size(word6);
        gt(round(len/2)+24:round(len/2)+23+len6,round(wid/2)+24:round(wid/2)+71) =word6;
    else
        word6=imresize(word6,[32,NaN]);
        [len6,wid6,~]=size(word6);
        gt(round(len/2)+24:round(len/2)+55,round(wid/2)+24:round(wid/2)+wid6+23) =word6;
    end
    
    
    figure;imshow(gt);
    save_name=[ground_value '.bmp'];
    imwrite(gt,save_name);
    close;
    
end