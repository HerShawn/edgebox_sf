
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
    
    %自适应的设置从第几个阈值分割起始
    E_thresh=median(median(E1(find(E1>0))))
    begin_index= round(100*median(median(E1(find(E1>E_thresh)))))
    %% 【1】稳定性 MSTB: Maximal Stable Text Boundary 最稳定的文字边缘
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
        %         binaryzation =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        %         edgeNum=length(edgeStats);
        %         for ii=1:edgeNum
        %             text_str{ii} = num2str(ii);
        %         end
        %         binaryzation = insertText(binaryzation,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        %         clear text_str
        %         save_name=[img_value '-' num2str(i) '-binaryzation-' num2str(edgeNum) '.bmp'];
        %         imwrite(1-binaryzation,save_name);
        
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
                     
        %欧拉数和（面积排在前两位）结合起来用
        %         bbox = vertcat(edgeStats.BoundingBox);
        %         w = bbox(:,3);
        %         h = bbox(:,4);
        %         bboxArea=w.*h;
        %         [~,index] = sortrows([edgeStats.Area].');
        %         thresh_Area=edgeStats(index(end-2)).Area;
        %形态学和稳定性结合起来；存在上述情况，说明存在较严重的粘连情况，则直接跳到下一个阈值分割；
        %         if(~isempty(find(([edgeStats.EulerNumber] <= -10 )&([edgeStats.Area]>=thresh_Area))))
        %         if(~isempty(find(([edgeStats.EulerNumber] <= -10 )&(bboxArea>5*median(bboxArea))')))
        %             continue;
        %         end

        bbox = vertcat(edgeStats.BoundingBox);
        
        %图形学判别后的结果展示
        afterMorphology =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        afterMorphologyEdgeNum=length(edgeStats);
        for ii=1:afterMorphologyEdgeNum
            text_str{ii} = num2str(ii);
        end
        afterMorphology = insertText(afterMorphology,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-afterMorphology-' num2str(afterMorphologyEdgeNum) '.bmp'];
        imwrite(1-afterMorphology,save_name);
        
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
        
        
        %去掉【一个像素】后的结果展示
        afterMorphology2 =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        afterMorphologyEdgeNum=length(edgeStats);
        for ii=1:afterMorphologyEdgeNum
            text_str{ii} = num2str(ii);
        end
        afterMorphology2 = insertText(afterMorphology2,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-afterMorphology2-' num2str(afterMorphologyEdgeNum) '.bmp'];
        imwrite(1-afterMorphology2,save_name);
        
        
        
        
        %% 【3】粘连点检测及断开 ：闭合性；内含bbox数目
        %
        %         %粘连只可能发生在闭合边缘CC中
        %         closure=zeros(1,afterMorphologyEdgeNum);
        %         for ii=1:afterMorphologyEdgeNum
        %             closure = edgeStats(ii).FilledArea/edgeStats(ii).Area;
        %         end
        %         filterIdx = closure == 1 ;
        %         edgeStats(filterIdx) = [];
        %         clear filterIdx
        %         bbox = vertcat(edgeStats.BoundingBox);
        %
        %         %粘连很可能发生在内含bbox数目较多的边缘CC中
        %         adjoin= bboxOverlapRatio(bbox, bbox,'Min');
        %         % 设bbox与它自己没有连通关系
        %         n = size(adjoin,1);
        %         adjoin(1:n+1:n^2) = 0;
        %         %计算每个bbox完全内含其它bbox的个数
        %         adj_index=zeros(1,n);
        %         for adj=1:n
        %             adj_index(1,adj)=length(find(adjoin(adj,:)==1));
        %         end
        %         %大于内含bbox数目中值的两倍的bbox在检测粘连点的考虑范围内
        %         adj_thresh=max(1,median(adj_index))*2;
        %         adjIdx=adj_index>adj_thresh;
        %         adjStats=edgeStats(adjIdx);
        %
        %         %对候选bbox进行粘连点检测
        %         adjoinPointImg=zeros(size(skeletImg,1),size(skeletImg,2));
        %         for adjNum=1:length(adjStats)
        %             as=adjStats(adjNum);
        %             for iii=1:length(as.PixelList)
        %                 %边缘上的当前像素点
        %                 a_x=as.PixelList(iii,1);
        %                 a_y=as.PixelList(iii,2);
        %                 %该像素点的8连通域内有3个领域像素点，则断掉该像素点
        %                 if length(find(skeletImg(a_y-1:a_y+1,a_x-1:a_x+1)>0))>3
        %                     adjoinPointImg(a_y,a_x)=1;
        %                 end
        %             end
        %         end
        %
        %        %显示粘连点的检测结果
        %
        %        [adjoinX,adjoinY]=find(adjoinPointImg>0);
        %        for adjPos=1:length(adjoinX)
        %            afterMorphology(adjoinX(adjPos,:),adjoinY(adjPos,:),:)=[0 1 0];
        %        end
        %        save_name=[img_value '-' num2str(i) '-adjoinDetect.bmp'];
        %        imwrite(1-afterMorphology,save_name);
        %
        %        %断开所有粘连点
        %        for adjPos=1:length(adjoinX)
        %            skeletImg(adjoinX(adjPos,:),adjoinY(adjPos,:),:)=0;
        %        end
        %        save_name=[img_value '-' num2str(i) '-adjoinBroken.bmp'];
        %        imwrite(1-skeletImg,save_name);
        %
        %        %断开粘连点后再次经过形态学处理后的图
        %        [afterAjoin_skeletImg,afterAjoin_bbox]=classifyGraphic(skeletImg);
        %        save_name=[img_value '-' num2str(i) '-adjoinBrokenMorphology.bmp'];
        %        imwrite(1-afterAjoin_skeletImg,save_name);
        %
        %        %gmse=256-rgb2gray(sfMask(g,skeletImg));
        
%         break;
        
    end
end


