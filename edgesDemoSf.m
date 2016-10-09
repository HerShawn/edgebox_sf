% % Demo for Structured Edge Detector (please see readme.txt first).
% 
% addpath('piotr_toolbox');
% addpath(genpath(pwd));
% 
% %% set opts for training (see edgesTrain.m)
% opts=edgesTrain();                % default options (good settings)
% opts.modelDir='models/';          % model will be in models/forest
% opts.modelFnm='modelBsds';        % model name
% opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
% opts.useParfor=0;                 % parallelize if sufficient memory
% 
% %% train edge detector (~20m/8Gb per tree, proportional to nPos/nNeg)
% tic, model=edgesTrain(opts); toc; % will load model if already trained
% 
% %% set detection parameters (can set after training)
% model.opts.multiscale=0;          % for top accuracy set multiscale=1
% model.opts.sharpen=2;             % for top speed set sharpen=0
% model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
% model.opts.nThreads=4;            % max number threads for evaluation
% model.opts.nms=0;                 % set to true to enable nms
% 
% %% evaluate edge detector on BSDS500 (see edgesEval.m)
% if(0), edgesEval( model, 'show',1, 'name','' ); end

%% detect edge and visualize results

clear;close;clc;
do_dir='C:\Users\Administrator\Desktop\N_gt\sf-0.06\';
dir_img = dir([do_dir '*.bmp']);
num_img = length(dir_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir  img_value '.bmp'];
    g = imread(img_name);
%     g=imresize(g,[640,NaN]);

     %SF边缘检测
%      E=edgesDetect(g,model);     
%     G=imresize(E,[640,NaN]);
%     F=im2bw(G,0.12);
%     imshow(1-F);

    %制作segmentation
    S=im2uint16(g);
%     S=rgb2gray(S);
    S=65536-S;
    S(find(S>=2))=15;
      
    %Canny边缘检测
%     I=rgb2gray(g);               % 转化为灰色图像  
    G = edge(S,'canny');  % 调用canny函数  
    
    
    groundTruth={struct('Segmentation',S, 'Boundaries',G)};
    save(['C:\Users\Administrator\Desktop\N_gt\sf-0.06-mat\' img_value '.mat'],'groundTruth');
    
    
%     figure,imshow(1-G);     % 显示分割后的图像，即梯度图像  
%     
%     save_name=[img_value '.jpg'];
%     print(gcf, '-dpng', save_name);
%     close all;
%     clc;
end

