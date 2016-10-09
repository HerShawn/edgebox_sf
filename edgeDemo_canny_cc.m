% Demo for Structured Edge Detector (please see readme.txt first).
close all
clear
clc
addpath('piotr_toolbox');
addpath(genpath(pwd));
%% set opts for training (see edgesTrain.m)
opts=edgesTrain();                % default options (good settings)
opts.modelDir='models/';          % model will be in models/forest
opts.modelFnm='modelBsds';        % model name
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
opts.useParfor=0;                 % parallelize if sufficient memory
%% train edge detector (~20m/8Gb per tree, proportional to nPos/nNeg)
model=edgesTrain(opts); % will load model if already trained
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
t_model=t_edgesTrain(opts);
%% set detection parameters (can set after training)
model.opts.multiscale=0;          % for top accuracy set multiscale=1
model.opts.sharpen=2;             % for top speed set sharpen=0
model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
model.opts.nThreads=4;            % max number threads for evaluation
model.opts.nms=0;                 % set to true to enable nms

t_model.opts.multiscale=0;          % for top accuracy set multiscale=1
t_model.opts.sharpen=2;             % for top speed set sharpen=0
t_model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
t_model.opts.nThreads=4;            % max number threads for evaluation
t_model.opts.nms=0;                 % set to true to enable nms
%% detect edge and visualize results

dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    
    
    E1=edgesDetect(g,t_model);
    %     E2=edgesDetect(g,model);
    %     figure(1);imshow(1-E1);
    %     figure(2);imshow(1-E2);
    %     E=E1-E2;
    
    
    %     thresh=median(median(E(find(E>0.1))));
    thresh=median(median(E1(find(E1>0.25))));
    
    %     E(find(E<thresh))=0;
    E1(find(E1<thresh))=0;
    E1(find(E1>thresh))=1;
    %     E(find(E>=thresh))= E(find(E>=thresh))+0.7;
    
    
    %      figure(1);imshow(1-E1);
    edgeMap = edge(E1, 'canny');
%     figure(2);imshow(1-edgeMap);
    
    %     swtMap=edgeSwt(E1,-1);
    %     figure(3);imshow(1-swtMap);
    %
    
    [L,num] = bwlabel(edgeMap,8);      % 计算img2的八连通区域，L为返回的带标记图像，尺寸与img2相同，num为连通区域数目；
    mserStats = regionprops(L, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');
    
    bbox = vertcat(mserStats.BoundingBox);
    IExpandedBBoxes = insertShape(double(edgeMap),'Rectangle',bbox,'LineWidth',1);
%     figure(3);
%     imshow(1-IExpandedBBoxes);
    
    save_name=[img_value '.bmp'];
    %     print(2, '-dpng', save_name);
    imwrite(1-IExpandedBBoxes,save_name);
    close all;
    %     clear;
    
end
