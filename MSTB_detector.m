
%% ������ֵ�sfģ��
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
dir_img = dir('C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 1:num_img
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %% ��1���ȶ��� MSTB: Maximal Stable Text Boundary ���ȶ������ֱ�Ե
    for i=5:2:19
        E1=E_tmp;
        %����Ӧ��ֵ�ָ� 8���ȶ���
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        
        % skelet: ϡ�裻 ��������ճ������ĶϿ���
        regionImage = logical(E1);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        skeletImg=double(skeletonImage);
        
        % ��ͨ���������
        [L,num] = bwlabel(skeletImg,8);
        mserStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity','PixelList');
        
        %% ��2��ͼ��ѧ�б�
        bbox = vertcat(mserStats.BoundingBox);
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        bboxArea=w.*h;
        %��߱�
        filterIdx = aspectRatio' > 10 ;
        filterIdx = filterIdx |  aspectRatio' <0.2 ;
        %�˵�̫С�����
        filterIdx = filterIdx | [mserStats.FilledArea] < 50 ;
        filterIdx = filterIdx | [mserStats.ConvexArea]./bboxArea' < 0.5 ;
        %ŷ�����ͣ��������ǰ��λ�����������
        [~,index] = sortrows([mserStats.Area].');
        thresh_Area=mserStats(index(end-2)).Area;
        filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
        %ͼ��ѧ���ȶ��Խ���������������������˵�����ڽ����ص�ճ���������ֱ��������һ���ȶ��ԣ�
        %ͳ�ƣ���8�������������ϣ�˵��ճ�����أ��ǾͲ��ܶ�ÿ��CC��������Ӧ������ԭͼ����ɫ������
        if(~isempty(find(([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area))))
            continue;
        end
        mserStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);
        
        %ͼ��ѧ�б��Ľ��չʾ
%         afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
%         for ii=1:length(mserStats)
%             text_str{ii} = num2str(ii);
%         end
%         afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
%         %         figure(1);imshow(1-afterBBoxes);
%         save_name=[img_value '-' num2str(i) '-graphics.bmp'];
%         imwrite(1-afterBBoxes,save_name);
        
        %% ��3���ı��оۼ�
        
        %����Ӧ�������жϣ���1�����ȶ���i���ڵ����ĸ��ȶ����ж��Ƿ�ճ�����أ���Ҫ�Ͽ�����2�����ĸ�bbox��Ҫ������aspect,area��
        %2016-10-11 ��1����ͼ��ѧ�е�ŷ�������area�Ѿ������жϵ�ĳ���ȶ�����д����ˣ�
        %��2�������ĸ�bbox���ж�����bboxOverlapRatio(min)=1���ܷ�����Щbbox���ܷ��������صĶ������⡣
        adjoin= bboxOverlapRatio(bbox, bbox,'Min');
        % ��bbox�����Լ�û����ͨ��ϵ
        n = size(adjoin,1);
        adjoin(1:n+1:n^2) = 0;
        adj_index=zeros(1,n);
        for adj=1:n
            adj_index(1,adj)=length(find(adjoin(adj,:)==1));
        end
        %�ں�3��bbox���п���ճ��
        adj_thresh=max(1,median(adj_index))*4;
        adjIdx=adj_index>adj_thresh;
        adjStats=mserStats(adjIdx);
        
        %%  2016-10-12 ��adjoin�㲢����Ͽ�
        for adj2=1:length(find(adjIdx>0))
            %�պϵı�ԵCC���п���ճ��
            if adjStats(adj2).FilledArea/adjStats(adj2).Area>1
                %��ʾ��ճ����ԵCC
%                 %                 imshow(adjStats(adj2).Image);
%                 save_name=[img_value '-' num2str(i) '-adjoin-' num2str(adj2) '.bmp'];
%                 imwrite(adjStats(adj2).Image,save_name);
                % �����ĺ��ķ���
                as=adjStats(adj2);
                %�����ı�Ҫ��Χ���ڴ˷�Χ�⣬û�б�Ҫ����
                x_min=round(as.BoundingBox(1,1)+as.BoundingBox(1,3)*0.15);
                x_max=round(as.BoundingBox(1,1)+as.BoundingBox(1,3)*0.85);
                y_min=round(as.BoundingBox(1,2)+as.BoundingBox(1,4)*0.15);
                y_max=round(as.BoundingBox(1,2)+as.BoundingBox(1,4)*0.85);
                %������Ե
                for iii=1:length(as.PixelList)
                    %��Ե�ϵĵ�ǰ���ص�
                    a_x=as.PixelList(iii,1);
                    a_y=as.PixelList(iii,2);
                    %�����ص��8��ͨ������3���������ص㣬��ϵ������ص�
                    if ((x_min<a_x)&&(a_x<x_max))&&((y_min<a_y)&&(a_y<y_max))...
                            &&(length(find(skeletImg(a_y-1:a_y+1,a_x-1:a_x+1)>0))>3)
                        skeletImg(a_y,a_x)=0;
                    end
                end
            end
        end
        %��ʾ�������skeletͼ
%         %         imshow(skeletImg);
%         save_name=[img_value '-' num2str(i) '-brokeAdjoin.bmp'];
%         imwrite(skeletImg,save_name);      
        %�����ٴξ���ͼ��ѧ������ͼ
        [afterAjoin_skeletImg,afterAjoin_bbox]=classifyGraphic(skeletImg);
        %         figure(1);imshow(1-afterBBoxes);
%         save_name=[img_value '-' num2str(i) '-afterAdjoin-graphics.bmp'];
%         imwrite(1-afterAjoin_skeletImg,save_name);


        %% �ı������š��ۼ�    
        
        % �� [x y width height] �� [xmin ymin xmax ymax]
        xmin = afterAjoin_bbox(:,1);
        ymin = afterAjoin_bbox(:,2);
        xmax = xmin + afterAjoin_bbox(:,3) - 1;
        ymax = ymin + afterAjoin_bbox(:,4) - 1;
        % ��չbbox,ʹ��bbox���Ծۼ����ı���
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
        % bbox����ô��չ��Ҳ���ܳ���ԭͼ�ı߽�
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(skeletImg,2));
        ymax = min(ymax, size(skeletImg,1));
        % ��չ���bbox�Ľ��չʾ
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
        % 2016-10-11: �ص㣡���� �ı��з����ۼ�����
        %union>0����---> bbox�ߣ� h1/h2>0.6;�غ�/max(h1,h2)>0.25
        overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
        % ��bbox�����Լ�û����ͨ��ϵ
        n = size(overlapRatio,1);
        overlapRatio(1:n+1:n^2) = 0;
        % Create the graph
        gh = graph(overlapRatio);
        % Find the connected text regions within the graph
        componentIndices = conncomp(gh);
        
        %% �����cc�����ı��п��ܲ���
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
        %% ֻ��һ��region����ͨ������Ҫ����������׶� ��������
        textBBoxes(numRegionsInGroup == 1, :) = [];
        
        
        
        %% ���ս��
        % Show the final text detection result.
        ITextRegion = insertShape(skeletImg, 'Rectangle', textBBoxes,'LineWidth',1);
        %         figure(3);imshow(1-ITextRegion);
        %������ͼ��
        %         save_name=[img_value '-' num2str(i) '-' num2str(length(mserStats)) '.bmp'];
        save_name=[img_value '-' num2str(i) '-merge.bmp'];
        imwrite(1-ITextRegion,save_name);
    end
    
end
