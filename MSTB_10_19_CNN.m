
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

%% Maximally Stable Edge Text Detector ���ȶ���Ե���ּ����
dir_img = dir('C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 197:197
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %����Ӧ�����ôӵڼ�����ֵ�ָ���ʼ
    E_thresh=median(median(E1(find(E1>0))))
    begin_index= round(100*median(median(E1(find(E1>E_thresh)))))
    %% ��1����Ե�ȶ��ȶ��� 
    %     for i=begin_index:1:20
    for i=begin_index:1:20
        E1=E_tmp;
        %����Ӧ��ֵ�ָ�
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        
        % �Ǽ�ͼ: ��ͨ�ԡ��պ��Բ�����ʹ��Ե��ȱ�Ϊ1���ü��ͶϿ�ճ����
        regionImage = logical(E1);
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        skeletImg=double(skeletonImage);
        
        % ��ͨ���������
        [L,num] = bwlabel(skeletImg,8);
        edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity','PixelList');
        
        %�ڵ�ǰ��ֵ�ָ��µĽ��չʾ
        bbox = vertcat(edgeStats.BoundingBox);
             
        %% ��2����̬ѧ�б�
        
        %�˵�̫С�����
        filterIdx = [edgeStats.FilledArea] < 50 ;
        
        %��߱�
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = filterIdx | aspectRatio' > 8 ;
        filterIdx = filterIdx |  aspectRatio' <1/7 ;
        
        %��������̬ѧ�Ķ��˳���
        edgeStats(filterIdx) = [];
        clear filterIdx
        
        if((length(find([edgeStats.EulerNumber] <= -10 ))>2)||(length(edgeStats)>200))
            continue;
        end
                               
        %2016-10-16��ȥ��һ�����صġ�
        filter_index=[];
        for ii=1:length(edgeStats)
            statsImg=edgeStats(ii).Image;
            [h,w]=size(statsImg);
            
            %����
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
            
            %����
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
        
        % ��ͨ���������
        [L,num] = bwlabel(skeletImg,8);
        edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea','Image',...
            'EulerNumber','Solidity','Eccentricity','PixelList');  
        %�ڵ�ǰ��ֵ�ָ��µĽ��չʾ
        bbox = vertcat(edgeStats.BoundingBox);
                
        %�˵�̫С�����
        filterIdx = [edgeStats.FilledArea] < 50 ;   
        %��߱�
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = filterIdx | aspectRatio' > 8 ;
        filterIdx = filterIdx |  aspectRatio' <1/7 ;      
        %��������̬ѧ�Ķ��˳���
        edgeStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(edgeStats.BoundingBox);
            
        
        %2016-10-17 �ڴ���4��median��bbox�в���4�����ϵ�ճ������continue��ֱ��break;
        adjoin= bboxOverlapRatio(bbox, bbox);
        n = size(adjoin,1);
        adjoin(1:n+1:n^2) = 0;
        %����bbox�໥��ճ����Ŀ
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
        
        %�Ƚ���ȫ�����������Ƶ�
        thresh=0.9;
        [selectedBbox,~] = selectStrongestBbox(bbox,bboxArea,'RatioType','Min','OverlapThreshold',thresh);        
        
        
        
        
       %% �ı��з��� һ�еĸ� ���� ��Ⱥ ճ���� 
        
        % �� [x y width height] �� [xmin ymin xmax ymax]
        xmin = selectedBbox(:,1);
        ymin = selectedBbox(:,2);
        xmax = xmin + selectedBbox(:,3) - 1;
        ymax = ymin + selectedBbox(:,4) - 1;
        % ��չbbox,ʹ��bbox���Ծۼ����ı���
        y_expansionAmount=0.01;
        x_expansionAmount = median(selectedBbox(:,3))/2;
        ymin = (1-y_expansionAmount) * ymin;
        ymax = (1+y_expansionAmount) * ymax;
        xmin = xmin-x_expansionAmount;
        xmax =xmax+x_expansionAmount;
        % bbox����ô��չ��Ҳ���ܳ���ԭͼ�ı߽�
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(skeletImg,2));
        ymax = min(ymax, size(skeletImg,1));
        % ��չ���bbox�Ľ��չʾ
        expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
        % ��bbox�����Լ�û����ͨ��ϵ
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
       
        % �ı��о�����
        afterTextLine = insertShape(skeletImg, 'Rectangle', textBBoxes,'LineWidth',1);
        afterTextLineNum=size(textBBoxes,1);
        for ii=1:afterTextLineNum
            text_str{ii} = num2str(ii);
        end
        afterTextLine = insertText(afterTextLine,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-merge-' num2str(afterTextLineNum) '.bmp'];
        imwrite(1-afterTextLine,save_name);
        

        
        
       %% �������� MSER ���� �ж�����/������
        %CNN
        addpath(genpath('/detectorDemo'));
        for ii=1:size(textBBoxes,1)     
            %��ѡ��SF
            gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3),:);
            runDetectorDemo(gBbox);
        end
        

        % ���ȶ����ֱ�Ե����ĳ����ֵ�ָ�����������ǰ��ֵ�ָ��£����ֱ�Ե������
        break;        
    end
end


