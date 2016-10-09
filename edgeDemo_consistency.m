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
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
t_model=t_edgesTrain(opts);
%% set detection parameters (can set after training)
t_model.opts.multiscale=0;          % for top accuracy set multiscale=1
t_model.opts.sharpen=2;             % for top speed set sharpen=0
t_model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
t_model.opts.nThreads=4;            % max number threads for evaluation
t_model.opts.nms=0;                 % set to true to enable nms
%% detect edge and visualize results
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 157:157
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %稳定性 MSTB: Maximal Stable Text Boundary 最稳定的文字边缘
    for i=5:2:19
        E1=E_tmp;
        %自适应阈值分割
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        
        %实验：文本行分析之一：颜色，断连
        regionImage = logical(E1);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        figure(1);imshow(1-skeletonImage)
        
        
        %文本行分析之一：颜色，断连
        %         g=sfMask(g,E1);
        %         figure(1);imshow(g);
        
        %连通区域分析
        [L,num] = bwlabel(E1,8);
        mserStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity');
        
        %图形学判别
        bbox = vertcat(mserStats.BoundingBox);
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        bboxArea=w.*h;
        %宽高比
        filterIdx = aspectRatio' > 10 ;
        filterIdx = filterIdx |  aspectRatio' <0.2 ;
        %滤掉太小面积的
        filterIdx = filterIdx | [mserStats.FilledArea] < 50 ;
        filterIdx = filterIdx | [mserStats.ConvexArea]./bboxArea' < 0.5 ;
        %欧拉数和（面积排在前两位）结合起来用
        [~,index] = sortrows([mserStats.Area].');
        thresh_Area=mserStats(index(end-2)).Area;
        filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
        %图形学和稳定性结合起来；存在上述情况，说明存在较严重的粘连情况，则直接跳到下一轮稳定性；
        %统计：若8轮下来都不符合，说明粘连严重：那就不能对每个CC分析，而应对整个原图做颜色断连。
        if(~isempty(find(([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area))))
            continue;
        end
        mserStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);
        
        
        
        % 连通区域标注
        afterBBoxes = insertShape(double(E1),'Rectangle',bbox,'LineWidth',1);
        for ii=1:length(mserStats)
            text_str{ii} = num2str(ii);
        end
        length(mserStats)
        afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        figure(2);imshow(1-afterBBoxes);
        clear text_str
        
        
        %实验：mserStats的image属性
        for j = 1:numel(mserStats)  
            regionImage = mserStats(j).Image;           
            figure(3);imshow(1-regionImage)
            distanceImage = bwdist(~regionImage);
            skeletonImage = bwmorph(regionImage, 'thin', inf);
            figure(4);imshow(1-skeletonImage)           
        end
        
        
        %保存结果图像
        save_name=[img_value '-' num2str(i) '-' num2str(length(mserStats)) '.bmp'];
        imwrite(1-afterBBoxes,save_name);
    end
    
end
