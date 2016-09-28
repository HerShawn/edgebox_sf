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

for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E=edgesDetect(g,model);
    F=imresize(E,[640,NaN]);
    g=imresize(g,[640,NaN]);
    
     G=im2bw(F,0.1);
    img2 =bwareaopen(G,6,8);       %按照八连通规则，将面积小于6的连通区域滤除；
    [L,num] = bwlabel(img2,8);      % 计算img2的八连通区域，L为返回的带标记图像，尺寸与img2相同，num为连通区域数目； 
     mserStats = regionprops(L, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');
    
    bbox = vertcat(mserStats.BoundingBox);
    IExpandedBBoxes = insertShape(g,'Rectangle',bbox,'LineWidth',3);
    figure
    imshow(IExpandedBBoxes)
    save_name=[img_value '.jpg'];
    print(gcf, '-dpng', save_name);
    close
end