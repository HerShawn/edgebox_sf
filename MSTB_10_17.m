
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
for indexImg = 4:4
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %自适应的设置从第几个阈值分割起始
    E_thresh=median(median(E1(find(E1>0))))
    begin_index= round(100*median(median(E1(find(E1>E_thresh)))))
    %% 【1】边缘稳定稳定性 
    %     for i=begin_index:1:20
    for i=begin_index:1:20
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
        edgeStats(filterIdx) = [];
        clear filterIdx
        
        if((length(find([edgeStats.EulerNumber] <= -10 ))>2)||(length(edgeStats)>200))
            continue;
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
        edgeStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(edgeStats.BoundingBox);
            
        
        %2016-10-17 在大于4个median的bbox中产生4个以上的粘连，就continue，直到break;
        adjoin= bboxOverlapRatio(bbox, bbox);
        n = size(adjoin,1);
        adjoin(1:n+1:n^2) = 0;
        %计算bbox相互间粘连数目
        adj_index=zeros(1,n);
        for adj=1:n
            adj_index(1,adj)=length(find(adjoin(adj,:)>0));
        end
        w = bbox(:,3);
        h = bbox(:,4);
        bboxArea=w.*h;
        if(~isempty(find(bboxArea>4*median(bboxArea))))
            if(~isempty(find(adj_index>3)))
                continue
            end
        end
        
        %先将完全被包含的抑制掉
        thresh=0.9;
        [selectedBbox,~] = selectStrongestBbox(bbox,bboxArea,'RatioType','Min','OverlapThreshold',thresh);
        
        
        %去掉【一个像素】后的结果展示
        afterMorphology2 =insertShape(skeletImg,'Rectangle',selectedBbox,'LineWidth',1);
        afterMorphologyEdgeNum=length(selectedBbox);
        for ii=1:afterMorphologyEdgeNum
            text_str{ii} = num2str(ii);
        end
        afterMorphology2 = insertText(afterMorphology2,selectedBbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-afterMorphology2-' num2str(afterMorphologyEdgeNum) '.bmp'];
        imwrite(1-afterMorphology2,save_name);
         
        
        %% 分类器： MSER 属性 判断文字/非文字
        
        for ii=1:length(selectedBbox)
            
            gBbox=g(selectedBbox(ii,2):selectedBbox(ii,2)+selectedBbox(ii,4)-1,selectedBbox(ii,1):selectedBbox(ii,1)+selectedBbox(ii,3),:)-1;
            gI = rgb2gray(gBbox);
            maxArea=selectedBbox(ii,3)*selectedBbox(ii,4);
            minArea=maxArea/10;
            [mserRegions, mserConnComp] = detectMSERFeatures(gI, ...
                'RegionAreaRange',[100 10000],'ThresholdDelta',1);           
            figure
            imshow(gI)
            hold on
            plot(mserRegions, 'showPixelList', true,'showEllipses',false)
            title('MSER regions')
            hold off
                       
             mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
                'Solidity', 'Extent', 'Euler', 'Image');
            
            bbox = vertcat(mserStats.BoundingBox);
            w = bbox(:,3);
            h = bbox(:,4);
            aspectRatio = w./h;
            
            filterIdx = aspectRatio' > 7;
            filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
            filterIdx = filterIdx | [mserStats.Solidity] < .3;
            filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
            filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
            
            mserStats(filterIdx) = [];
            mserRegions(filterIdx) = [];
            clear filterIdx

            figure
            imshow(gI)
            hold on
            plot(mserRegions, 'showPixelList', true,'showEllipses',false)
            title('After Removing Non-Text Regions Based On Geometric Properties')
            hold off
            
            strokeWidthThreshold = 0.35;
            for j = 1:numel(mserStats)               
                regionImage = mserStats(j).Image;
                regionImage = padarray(regionImage, [1 1], 0);             
                distanceImage = bwdist(~regionImage);
                skeletonImage = bwmorph(regionImage, 'thin', inf);                
                strokeWidthValues = distanceImage(skeletonImage);             
                strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);              
                strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;     
            end            
            mserRegions(strokeWidthFilterIdx) = [];
            mserStats(strokeWidthFilterIdx) = [];
            clear strokeWidthFilterIdx
            figure
            imshow(gI)
            hold on
            plot(mserRegions, 'showPixelList', true,'showEllipses',false)
            title('After Removing Non-Text Regions Based On Stroke Width Variation')
            hold off
            close all
        end
        
        
        
        
        
        
        % 最稳定文字边缘：在某个阈值分割下跳出；当前阈值分割下，文字边缘最显著
        break;        
    end
end


