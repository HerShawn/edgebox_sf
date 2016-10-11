
%% 针对文字的sf模型
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

%% Maximally Stable Text Boundary Detector
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 36:36
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %% 【1】稳定性 MSTB: Maximal Stable Text Boundary 最稳定的文字边缘
    for i=5:2:19
        E1=E_tmp;
        %自适应阈值分割 8个稳定域
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        
        % skelet: 稀疏； 好做“对粘连区域的断开”
        regionImage = logical(E1);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        skeletImg=double(skeletonImage);
        
        % 连通区域的属性
        [L,num] = bwlabel(skeletImg,8);
        mserStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity');
        
        %% 【2】图形学判别
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
        
        %图形学判别后的结果展示
        afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        for ii=1:length(mserStats)
            text_str{ii} = num2str(ii);
        end
        length(mserStats);
        afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
%         figure(1);imshow(1-afterBBoxes);
        save_name=[img_value '-' num2str(i) '-graphics.bmp'];
        imwrite(1-afterBBoxes,save_name);
        
        %% 【3】文本行聚集
        
        %%  【3.1正在进行】 断开粘连 
        %首先应该做个判断：（1）看稳定性i现在到了哪个稳定域，判断是否粘连严重，需要断开；（2）看哪个bbox需要断链：aspect,area等
        
        %8连通域搜索，3断：
        
        
        %%
        
        % 从 [x y width height] 到 [xmin ymin xmax ymax]
        xmin = bbox(:,1);
        ymin = bbox(:,2);
        xmax = xmin + bbox(:,3) - 1;
        ymax = ymin + bbox(:,4) - 1;
        % 扩展bbox,使得bbox可以聚集成文本行
        x_expansionAmount = 0.05;
        y_expansionAmount=0.02;
        xmin = (1-x_expansionAmount) * xmin;
        ymin = (1-y_expansionAmount) * ymin;
        xmax = (1+x_expansionAmount) * xmax;
        ymax = (1+y_expansionAmount) * ymax;
        % bbox再怎么扩展，也不能超过原图的边界
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(skeletImg,2));
        ymax = min(ymax, size(skeletImg,1));
        % 扩展后的bbox的结果展示
        expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        IExpandedBBoxes = insertShape(skeletImg,'Rectangle',expandedBBoxes,'LineWidth',1);
        IExpandedBBoxes = insertText(IExpandedBBoxes,expandedBBoxes(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        figure(2);imshow(1-IExpandedBBoxes);
        save_name=[img_value '-' num2str(i) '-expend.bmp'];
        imwrite(1-IExpandedBBoxes,save_name);
        % 2016-10-11: 重点！！！ 文本行分析聚集过程
        %union>0相连---> bbox高： h1/h2>0.6;重合/max(h1,h2)>0.25
        overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
        % 设bbox与它自己没有连通关系
        n = size(overlapRatio,1);
        overlapRatio(1:n+1:n^2) = 0;
        % Create the graph
        gh = graph(overlapRatio);
        % Find the connected text regions within the graph
        componentIndices = conncomp(gh);
        
        %% 这个将cc连成文本行可能不做
        %  merge multiple neighboring bounding boxes into a single bounding box by computing the
        % minimum and maximum of the individual bounding boxes that make up each connected component.
        % Merge the boxes based on the minimum and maximum dimensions.
        xmin = accumarray(componentIndices', xmin, [], @min);
        ymin = accumarray(componentIndices', ymin, [], @min);
        xmax = accumarray(componentIndices', xmax, [], @max);
        ymax = accumarray(componentIndices', ymax, [], @max);
        % Compose the merged bounding boxes using the [x y width height] format.
        textBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        %%
        
        % suppress false text detections by removing bounding boxes made up of just one text region.
        numRegionsInGroup = histcounts(componentIndices);
        %% 只有一个region的连通区域组要进入分类器阶段 【待做】
        textBBoxes(numRegionsInGroup == 1, :) = [];
        
        
        
        %% 最终结果
        % Show the final text detection result.
        ITextRegion = insertShape(skeletImg, 'Rectangle', textBBoxes,'LineWidth',1);
        figure(3);imshow(1-ITextRegion);
        %保存结果图像
        %         save_name=[img_value '-' num2str(i) '-' num2str(length(mserStats)) '.bmp'];
        save_name=[img_value '-' num2str(i) '-merge.bmp'];
        imwrite(1-ITextRegion,save_name);
    end
    
end
