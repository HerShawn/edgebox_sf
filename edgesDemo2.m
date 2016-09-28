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
tic, model=edgesTrain(opts); toc; % will load model if already trained
%% set detection parameters (can set after training)
model.opts.multiscale=0;          % for top accuracy set multiscale=1
model.opts.sharpen=2;             % for top speed set sharpen=0
model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
model.opts.nThreads=4;            % max number threads for evaluation
model.opts.nms=0;                 % set to true to enable nms
%% evaluate edge detector on BSDS500 (see edgesEval.m)
if(0), edgesEval( model, 'show',1, 'name','' ); end
%% detect edge and visualize results
do_dir='D:\edgebox-contour-neumann三种检测方法的比较\';
dir_img = dir([do_dir 'Challenge2_Test_Task12_Images\*.jpg']);
num_img = length(dir_img);
for indexImg = 3:3
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E=edgesDetect(g,model);
    F=imresize(E,[640,NaN]);
    G=im2bw(F,0.12);
    [H, theta, rho] = hough(G, 'RhoResolution',0.4 ,'Theta', -90);
    %     ,'Theta', -90
    P = houghpeaks(H, 30 ,'threshold',ceil(0.2*max(H(:))));
    lines = houghlines(G, theta, rho, P,'FillGap',10,'MinLength',7);
    h=figure(indexImg);imshow(G, []), hold on
    for k = 1: length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:, 1), xy(:, 2), 'LineWidth', 4, 'Color','green');
        plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
        plot(xy(2,1),xy(2,2),'x','LineWidth',4,'Color','red');
    end
    save_name=[img_value '.jpg'];
    print(h, '-dpng', save_name);
    close
%     detectMSERFeatures
end
