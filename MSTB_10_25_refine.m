
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
%% 基于MSE（最稳定边缘）的文字边缘检测子
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 184:184
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    % 如果fusion.mat存在，则直接进入refine阶段
    % 否则，从MSE,text line analysis,classifier,fusion一步一步做，直到得到fusion.mat
    if(~exist([img_value '-fusion.mat'], 'file'))
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
        %% 【1】边缘稳定性
        % fusion各个阈值中的bbox，用(NMS,overlap,0.5)
        fusionBbox=[];
        % 有些图片因为欧拉数或粘连点数过多而导致全部跳过；当全部跳过时取最后一个阈值。
        skipNum=0;
        % 边缘稳定性的实现：一个自适应的阈值范围
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
            %% 【2】 skelet 特征
            skeletImg=double(skeletonImage);
            % 连通区域的属性
            [L,num] = bwlabel(skeletImg,8);
            edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
                'FilledArea','Extent' ,'ConvexArea','Image',...
                'EulerNumber','Solidity','Eccentricity','PixelList');
            %在当前阈值分割下的结果展示
            bbox = vertcat(edgeStats.BoundingBox);
            %% 【3】形态学判别
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
            %% 【4】 欧拉数/粘连点过多的skelet所在阈值不适合，跳过
            if((length(find([edgeStats.EulerNumber] <= -10 ))>2)||(length(edgeStats)>150))
                % 不能完全跳过
                skipNum=skipNum+1;
                if skipNum~=mseEnd
                    continue;
                end
            end
            %% 【5】 1 pixel 特征
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
            %% MSE提取的proposals得到了，继续下面的粗、细定位步骤
            
            %% 【6】文本行分析
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
            %% 【7】分类器：
            addpath(genpath('/detectorDemo'));
            for ii=1:size(textBBoxes,1)
                gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3),:);
                score=runDetectorDemo_salient(gBbox);
                if score>0
                    fusionBbox=[fusionBbox ; [textBBoxes(ii,:) score]];
                end
            end
            clear textBBoxes
        end
    %% MSE+文本行+classify阶段结束
    
    %% 【8】fusion阶段：
    if size(fusionBbox,1)==0
        continue
    end
    %     [fusionBbox, fusionBboxScore]=selectStrongestBbox(fusionBbox(:,1:4),fusionBbox(:,5),'RatioType','Min','OverlapThreshold',0.85);
    [fusionBbox, fusionBboxScore]=selectStrongestBbox(fusionBbox(:,1:4),fusionBbox(:,5));
    fusionBbox=[fusionBbox fusionBboxScore];
    fusionBboxName=[img_value '-fusion' '.mat'];
    save (fusionBboxName ,'fusionBbox' );
    % 分类器处理后各个阈值的结果展示
    afterfusion = insertShape(g, 'Rectangle', fusionBbox(:,1:4),'LineWidth',1);
    afterfusionNum=size(fusionBbox,1);
    for ii=1:afterfusionNum
        text_str{ii} = num2str(fusionBbox(ii,5));
    end
    afterfusion = insertText(afterfusion,fusionBbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','red');
    clear text_str
    save_name=[img_value '-fusion' '.bmp'];
    imwrite(afterfusion,save_name);    
    end %  if(~exist([img_value '-fusion.mat'], 'file'))到这里就结束了
 
    %% 【9】refine阶段：
    load([img_value '-fusion.mat']);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    eliminateIdx=[];
    for ii=1:size(fusionBbox,1)
        if fusionBbox(ii,4)/fusionBbox(ii,3)>2 || fusionBbox(ii,5)<0.1
            eliminateIdx=[eliminateIdx ii];
            continue
        end
        gBbox=g(fusionBbox(ii,2):fusionBbox(ii,2)+fusionBbox(ii,4)-1,fusionBbox(ii,1):fusionBbox(ii,1)+fusionBbox(ii,3),:);
        score=runDetectorDemo_refine_classifier(gBbox,ii);
        if score==0
            eliminateIdx=[eliminateIdx ii];
        end    
    end
    fusionBbox(eliminateIdx,:)=[];
    if size(fusionBbox,1)==0
        continue
    end
    refineBboxName=[img_value '-refine' '.mat'];
    save (refineBboxName ,'fusionBbox' );
    % 分类器处理后各个阈值的结果展示
    afterRefine = insertShape(g, 'Rectangle', fusionBbox(:,1:4),'LineWidth',1);
    afterRefineNum=size(fusionBbox,1);
    for ii=1:afterRefineNum
        text_str{ii} = num2str(fusionBbox(ii,5));
    end
    afterRefine = insertText(afterRefine,fusionBbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','red');
    clear text_str
    save_name=[img_value '-refine' '.bmp'];
    imwrite(afterRefine,save_name);
    
end


