
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

%% Maximally Stable Edge Text Detector 最稳定边缘文字检测子
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 129:129
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %自适应的设置起始阈值分割起始
    E_thresh=median(median(E1(find(E1>0))));
    E_thresh= round(100*median(median(E1(find(E1>E_thresh)))));
    
    %边缘稳定性：自适应的设置阈值范围
    if E_thresh<6
        mseBegin=1;
        mseEnd=11;
    elseif E_thresh>20
        mseBegin=15;
        mseEnd=25;
    else
        mseBegin=E_thresh-5;
        mseEnd=E_thresh+5;
    end
    
    
    %% 【1】边缘稳定稳定性 
    skipNum=0;
     for i=mseBegin:1:mseEnd
        E1=E_tmp;
        %自适应阈值分割
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        
        % 骨架图: 连通性、闭合性不变下使边缘宽度变为1，好检测和断开粘连点
        regionImage = logical(E1);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        skeletImg=double(skeletonImage);
        
        % 连通区域的属性
        [L,num] = bwlabel(skeletImg,8);
        edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity','PixelList');
        
        %在当前阈值分割下的结果展示
        bbox = vertcat(edgeStats.BoundingBox);
             
        %% 【2】形态学判别
        
        %滤掉太小面积的
        filterIdx = [edgeStats.FilledArea] < 50 ;
        
        %宽高比
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = filterIdx | aspectRatio' > 8 ;
        filterIdx = filterIdx |  aspectRatio' <1/7 ;
        
        %不符合形态学的都滤除掉
        
        if  size(edgeStats,1)==length(find(filterIdx))
            continue
        end
        
        edgeStats(filterIdx) = [];
        clear filterIdx
        
        if((length(find([edgeStats.EulerNumber] <= -10 ))>2)||(length(edgeStats)>200))
            skipNum=skipNum+1;
            if skipNum~=mseEnd
                continue;
            end
        end
                               
        %2016-10-16【去掉一个像素的】
        filter_index=[];
        for ii=1:length(edgeStats)
            statsImg=edgeStats(ii).Image;
            [h,w]=size(statsImg);
            
            %纵向
            row1=find(sum(statsImg')==1);
            filter_index1=[];
            if length(row1)/h>0.8
            col1=zeros(1,length(row1));
            for iii=1:length(row1)
                [~,col]=find(statsImg(row1(iii),:)~=0);
                col1(1,iii)=col;
            end
            filter_index1=[col1+floor( edgeStats(ii).BoundingBox(1,1));row1+floor( edgeStats(ii).BoundingBox(1,2))];
            end
            
            %横向
            col2=find(sum(statsImg)==1);
            filter_index2=[];
            if length(col2)/w>0.8
            row2=zeros(1,length(col2));
            for iii=1:length(col2)
                [row,~]=find(statsImg(:,col2(iii))~=0);
                row2(1,iii)=row;
            end
            filter_index2=[col2+floor( edgeStats(ii).BoundingBox(1,1));row2+floor( edgeStats(ii).BoundingBox(1,2))];
            end
            filter_index=[filter_index filter_index1 filter_index2];
        end
        
        for ii=1:length(filter_index)
            skeletImg(filter_index(2,ii),filter_index(1,ii))=0;
        end
        
        % 连通区域的属性
        [L,num] = bwlabel(skeletImg,8);
        edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity','PixelList');  
        %在当前阈值分割下的结果展示
        bbox = vertcat(edgeStats.BoundingBox);
                
        %滤掉太小面积的
        filterIdx = [edgeStats.FilledArea] < 50 ;   
        %宽高比
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = filterIdx | aspectRatio' > 8 ;
        filterIdx = filterIdx |  aspectRatio' <1/7 ;      
        %不符合形态学的都滤除掉
        
        if  size(edgeStats,1)==length(find(filterIdx))
            continue
        end
        
        edgeStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(edgeStats.BoundingBox);
            
        
       
        
        
       %% 文本行分析 一行的高 排序 离群 粘连点 
        
        % 从 [x y width height] 到 [xmin ymin xmax ymax]
        xmin = bbox(:,1);
        ymin = bbox(:,2);
        xmax = xmin + bbox(:,3) - 1;
        ymax = ymin + bbox(:,4) - 1;
        % 扩展bbox,使得bbox可以聚集成文本行
        y_expansionAmount=0.01;
        x_expansionAmount = median(bbox(:,3))/2;
        ymin = (1-y_expansionAmount) * ymin;
        ymax = (1+y_expansionAmount) * ymax;
        xmin = xmin-x_expansionAmount;
        xmax =xmax+x_expansionAmount;
        % bbox再怎么扩展，也不能超过原图的边界
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(skeletImg,2));
        ymax = min(ymax, size(skeletImg,1));
        % 扩展后的bbox的结果展示
        expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
        % 设bbox与它自己没有连通关系
        n = size(overlapRatio,1);
        overlapRatio(1:n+1:n^2) = 0;
        % Create the graph
        gh = graph(overlapRatio);
        % Find the connected text regions within the graph
        componentIndices = conncomp(gh);        
        % Merge the boxes based on the minimum and maximum dimensions.
        xmin = accumarray(componentIndices', xmin, [], @min);
        ymin = accumarray(componentIndices', ymin, [], @min);
        xmax = accumarray(componentIndices', xmax, [], @max);
        ymax = accumarray(componentIndices', ymax, [], @max);
        % Compose the merged bounding boxes using the [x y width height] format.
        xmin( find(xmin~=1))=xmin( find(xmin~=1))+x_expansionAmount;
        xmax(find(xmax==size(skeletImg,2)))=xmax(find(xmax==size(skeletImg,2)))+x_expansionAmount;
        textBBoxes = [xmin ymin min(xmax-xmin+1-x_expansionAmount,size(skeletImg,2)-xmin) ymax-ymin+1];
       
        % 文本行聚类结果
        afterTextLine = insertShape(skeletImg, 'Rectangle', textBBoxes,'LineWidth',1);
        afterTextLineNum=size(textBBoxes,1);
        for ii=1:afterTextLineNum
            text_str{ii} = num2str(ii);
        end
        afterTextLine = insertText(afterTextLine,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-merge-' num2str(afterTextLineNum) '.jpg'];
        imwrite(1-afterTextLine,save_name);
        

  
        
       %% 分类器： 
        %CNN
        addpath(genpath('/detectorDemo'));
        salientMap=zeros(size(g,1),size(g,2));
        for ii=1:size(textBBoxes,1)     
            %先选择SF
            gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3),:);
%             save_gBname=[img_value '-阈值' num2str(i) '-bbox' num2str(ii)];
            score=runDetectorDemo_salient(gBbox);
            
            if score>0
                salientMap(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3))=1;
            end
           
        end
        save_name=[img_value '-salient' num2str(i) '.jpg'];
        imwrite(salientMap,save_name);
        clear salientMap
        clear textBBoxes
    end
end


