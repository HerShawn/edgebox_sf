
%% 利用制作的dataset训练出对文字边缘响应强的sf模型
close all
clear
clc
addpath('piotr_toolbox');
addpath(genpath(pwd));
% set opts for training (see edgesTrain.m)
opts=edgesTrain();                % default options (good settings)
opts.modelDir='models/';          % model will be in models/forest
opts.modelFnm='modelBsds';        % model name
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
opts.useParfor=0;                 % parallelize if sufficient memory
% train edge detector (~20m/8Gb per tree, proportional to nPos/nNeg)
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
t_model=t_edgesTrain(opts);
% set detection parameters (can set after training)
t_model.opts.multiscale=0;          % for top accuracy set multiscale=1
t_model.opts.sharpen=2;             % for top speed set sharpen=0
t_model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
t_model.opts.nThreads=4;            % max number threads for evaluation
t_model.opts.nms=0;                 % set to true to enable nms
%% 【1】检测子+分类器
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
load('initialSfIdx');
eIdx=[];
e10Idx=[];
yellowRedNums=[];
for indexImg = 1:num_img
    fusionBBox=[];
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    %自适应的设置起始阈值分割起始
    E_thresh=initialSfIdx(1,indexImg);
    E_thresh2=median(median(E1(find(E1>0))));
    E_thresh2= round(100*median(median(E1(find(E1>E_thresh2)))));
    E_thresh=max(E_thresh,E_thresh2);
    if(exist([img_value '-' num2str(E_thresh) '.mat'], 'file'))
        load([img_value '-' num2str(E_thresh) '.mat']);
        fusionBBox=[fusionBBox; expandedBBoxes];
        expandedBBoxes=[];
    else
        eIdx=[eIdx indexImg];
    end
    if(exist([img_value '-' num2str(E_thresh+10) '.mat'], 'file'))
        load([img_value '-' num2str(E_thresh+10) '.mat']);
        fusionBBox=[fusionBBox; expandedBBoxes];
        expandedBBoxes=[];
    else
        e10Idx=[e10Idx indexImg];
    end
    if((~exist([img_value '-' num2str(E_thresh) '.mat'], 'file'))&&(~exist([img_value '-' num2str(E_thresh+10) '.mat'], 'file')))
        continue
    end
    %% 【2】文本行
    % 从 [x y width height] 到 [xmin ymin xmax ymax]
    xmin = fusionBBox(:,1);
    ymin = fusionBBox(:,2);
    xmax = xmin + fusionBBox(:,3) - 1;
    ymax = ymin + fusionBBox(:,4) - 1;
    % bbox 不可以超过原图的边界
    xmin = max(xmin, 1);
    ymin = max(ymin, 1);
    xmax = min(xmax, size(g,2));
    ymax = min(ymax, size(g,1));
    expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
    % bbox作为结点，邻接关系作为边，建图
    overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
    n = size(overlapRatio,1);
    overlapRatio(1:n+1:n^2) = 0;
    gh = graph(overlapRatio);
    % 在图中找出连通的文本区域
    componentIndices = conncomp(gh);
    %【2.1】intra 组内找异常bbox
    %     intraAnalysis(img_value,componentIndices,fusionBBox,g);
    %求每个textBBoxes里有多少bboxes，作为该textBBoxes的权值
    textBBoxesNum=max(componentIndices);
    textBBoxesWeight=ones(textBBoxesNum,1);
    mserNum=zeros(textBBoxesNum,1);
    for ii=1:textBBoxesNum
        textBBoxesWeight(ii,1)=length(find(componentIndices==ii));
    end
    % 生成文本行
    xmin = accumarray(componentIndices', xmin, [], @min);
    ymin = accumarray(componentIndices', ymin, [], @min);
    xmax = accumarray(componentIndices', xmax, [], @max);
    ymax = accumarray(componentIndices', ymax, [], @max);
    textBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1 textBBoxesWeight mserNum];
    aftertextNum=size(textBBoxes,1);
    if aftertextNum==0
        img_value
        continue
    end
    %
    [yellowRedNum,textBBoxes,mserBBoxes]=textRefine_12_12(g,img_value,textBBoxes);
    yellowRedNums=[yellowRedNums;yellowRedNum];
end

save('yellowRedNums.mat','yellowRedNums');




