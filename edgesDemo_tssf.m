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
n_model=n_edgesTrain(opts); % will load model if already trained

%% set detection parameters (can set after training)
n_model.opts.multiscale=0;          % for top accuracy set multiscale=1
n_model.opts.sharpen=2;             % for top speed set sharpen=0
n_model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
n_model.opts.nThreads=4;            % max number threads for evaluation
n_model.opts.nms=1;                 % set to true to enable nms


%% detect edge and visualize results

dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    
    
    E1=edgesDetect(g,n_model);  
%     E2=edgesDetect(g,model);
%     figure(1);imshow(1-E1);
%     figure(2);imshow(1-E2);
%     E=E1-E2;


%     thresh=median(median(E1(find(E1>0.25))));
%     thresh=median(median(E1(find(E1>0.06))));

%     E(find(E<thresh))=0;
%     E1(find(E1<thresh))=0;
%     E1(find(E1>thresh))=25;
%     E(find(E>=thresh))= E(find(E>=thresh))+0.7;
   
    
%      figure(2);imshow(1-E1);
%     swtMap=edgeSwt(E1,-1);
%     figure(3);imshow(1-swtMap);
    
    
    save_name=[img_value '.bmp'];
%     print(2, '-dpng', save_name);
    imwrite(1-E1,save_name);
    close all;
%     clear;
   
end
