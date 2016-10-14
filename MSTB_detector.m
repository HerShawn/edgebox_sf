
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
for indexImg = 1:num_img
    
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
            'EulerNumber','Solidity','Eccentricity','PixelList');
        
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
%         afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
%         for ii=1:length(mserStats)
%             text_str{ii} = num2str(ii);
%         end
%         afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
%         %         figure(1);imshow(1-afterBBoxes);
%         save_name=[img_value '-' num2str(i) '-graphics.bmp'];
%         imwrite(1-afterBBoxes,save_name);
        
        %% 【3】文本行聚集
        
        %首先应该做个判断：（1）看稳定性i现在到了哪个稳定域，判断是否粘连严重，需要断开；（2）看哪个bbox需要断链：aspect,area等
        %2016-10-11 （1）由图形学中的欧拉数配合area已经可以判断到某个稳定域进行处理了；
        %（2）关于哪个bbox进行断链，bboxOverlapRatio(min)=1就能发现那些bbox可能发生了严重的断链问题。
        adjoin= bboxOverlapRatio(bbox, bbox,'Min');
        % 设bbox与它自己没有连通关系
        n = size(adjoin,1);
        adjoin(1:n+1:n^2) = 0;
        adj_index=zeros(1,n);
        for adj=1:n
            adj_index(1,adj)=length(find(adjoin(adj,:)==1));
        end
        %内含3个bbox很有可能粘连
        adj_thresh=max(1,median(adj_index))*4;
        adjIdx=adj_index>adj_thresh;
        adjStats=mserStats(adjIdx);
        
        %%  2016-10-12 找adjoin点并将其断开
        for adj2=1:length(find(adjIdx>0))
            %闭合的边缘CC才有可能粘连
            if adjStats(adj2).FilledArea/adjStats(adj2).Area>1
                %显示该粘连边缘CC
%                 %                 imshow(adjStats(adj2).Image);
%                 save_name=[img_value '-' num2str(i) '-adjoin-' num2str(adj2) '.bmp'];
%                 imwrite(adjStats(adj2).Image,save_name);
                % 断链的核心方法
                as=adjStats(adj2);
                %断链的必要范围：在此范围外，没有必要断链
                x_min=round(as.BoundingBox(1,1)+as.BoundingBox(1,3)*0.15);
                x_max=round(as.BoundingBox(1,1)+as.BoundingBox(1,3)*0.85);
                y_min=round(as.BoundingBox(1,2)+as.BoundingBox(1,4)*0.15);
                y_max=round(as.BoundingBox(1,2)+as.BoundingBox(1,4)*0.85);
                %遍历边缘
                for iii=1:length(as.PixelList)
                    %边缘上的当前像素点
                    a_x=as.PixelList(iii,1);
                    a_y=as.PixelList(iii,2);
                    %该像素点的8连通域内有3个领域像素点，则断掉该像素点
                    if ((x_min<a_x)&&(a_x<x_max))&&((y_min<a_y)&&(a_y<y_max))...
                            &&(length(find(skeletImg(a_y-1:a_y+1,a_x-1:a_x+1)>0))>3)
                        skeletImg(a_y,a_x)=0;
                    end
                end
            end
        end
        %显示断链后的skelet图
%         %         imshow(skeletImg);
%         save_name=[img_value '-' num2str(i) '-brokeAdjoin.bmp'];
%         imwrite(skeletImg,save_name);      
        %及其再次经过图形学处理后的图
        [afterAjoin_skeletImg,afterAjoin_bbox]=classifyGraphic(skeletImg);
        %         figure(1);imshow(1-afterBBoxes);
%         save_name=[img_value '-' num2str(i) '-afterAdjoin-graphics.bmp'];
%         imwrite(1-afterAjoin_skeletImg,save_name);


        %% 文本行扩张、聚集    
        
        % 从 [x y width height] 到 [xmin ymin xmax ymax]
        xmin = afterAjoin_bbox(:,1);
        ymin = afterAjoin_bbox(:,2);
        xmax = xmin + afterAjoin_bbox(:,3) - 1;
        ymax = ymin + afterAjoin_bbox(:,4) - 1;
        % 扩展bbox,使得bbox可以聚集成文本行
        %         x_expansionAmount = 0.03;
                y_expansionAmount=0.01;
        x_expansionAmount = median(afterAjoin_bbox(:,3))/2;
%         y_expansionAmount=median(afterAjoin_bbox(:,3))/10;
        %         xmin = (1-x_expansionAmount) * xmin;
                ymin = (1-y_expansionAmount) * ymin;
        %         xmax = (1+x_expansionAmount) * xmax;
                ymax = (1+y_expansionAmount) * ymax;
        xmin = xmin-x_expansionAmount;
%         ymin = ymin-y_expansionAmount;
        xmax =xmax+x_expansionAmount;
%         ymax = ymax+y_expansionAmount;
        % bbox再怎么扩展，也不能超过原图的边界
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(skeletImg,2));
        ymax = min(ymax, size(skeletImg,1));
        % 扩展后的bbox的结果展示
        expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
%         IExpandedBBoxes = insertShape(skeletImg,'Rectangle',expandedBBoxes,'LineWidth',1);
%          for ii=1:length(expandedBBoxes)
%             text_str{ii} = num2str(ii);
%         end
%         IExpandedBBoxes = insertText(IExpandedBBoxes,expandedBBoxes(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
%         clear text_str
%         %         figure(2);imshow(1-IExpandedBBoxes);
%         save_name=[img_value '-' num2str(i) '-expend.bmp'];
%         imwrite(1-IExpandedBBoxes,save_name);
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
        %         figure(3);imshow(1-ITextRegion);
        %保存结果图像
        %         save_name=[img_value '-' num2str(i) '-' num2str(length(mserStats)) '.bmp'];
        save_name=[img_value '-' num2str(i) '-merge.bmp'];
        imwrite(1-ITextRegion,save_name);
    end
    
end
