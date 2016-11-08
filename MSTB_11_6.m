
%% ����������datasetѵ���������ֱ�Ե��Ӧǿ��sfģ��
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
%% ����MSE�����ȶ���Ե�������ֱ�Ե�����
dir_img = dir('C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    % ���fusion.mat���ڣ���ֱ�ӽ���refine�׶�
    % ���򣬴�MSE,text line analysis,classifier,fusionһ��һ������ֱ���õ�fusion.mat
    if(~exist([img_value '-fusion.mat'], 'file'))
        img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
        g = imread(img_name);
        E1=edgesDetect(g,t_model);
        E_tmp=E1;
        %����Ӧ��������ʼ��ֵ�ָ���ʼ
        load('initialSfIdx');
        E_thresh=initialSfIdx(1,indexImg);
        E_thresh2=median(median(E1(find(E1>0))));
        E_thresh2= round(100*median(median(E1(find(E1>E_thresh2)))));
        E_thresh=max(E_thresh,E_thresh2);
        %% ��1����Ե�ȶ���
        % fusion������ֵ�е�bbox����(NMS,overlap,0.5)
        fusionBbox=[];
        % ��ЩͼƬ��Ϊŷ������ճ���������������ȫ����������ȫ������ʱȡ���һ����ֵ��
        skipNum=0;
        % ��Ե�ȶ��Ե�ʵ�֣�һ������Ӧ����ֵ��Χ
        %         for i=mseBegin:1:mseEnd
        for i=E_thresh:10:(E_thresh+10)
            E1=E_tmp;
            %����Ӧ��ֵ�ָ�
            thresh=median(median(E1(find(E1>(i/100)))));
            E1(find(E1<thresh))=0;
            E1(find(E1>thresh))=1;
            % �Ǽ�ͼ: ��ͨ�ԡ��պ��Բ�����ʹ��Ե���ȱ�Ϊ1���ü��ͶϿ�ճ����
            regionImage = logical(E1);
            distanceImage = bwdist(~regionImage);
            skeletonImage = bwmorph(regionImage, 'thin', inf);
            %% ��2�� skelet ����
            skeletImg=double(skeletonImage); 
            % ��ͨ���������
            [L,num] = bwlabel(skeletImg,8);
            edgeStats = regionprops(L, 'BoundingBox', 'Area', ...
                'FilledArea','Extent' ,'ConvexArea','Image',...
                'EulerNumber','Solidity','Eccentricity','PixelList');
            %�ڵ�ǰ��ֵ�ָ��µĽ��չʾ
            bbox = vertcat(edgeStats.BoundingBox);
            %% ��3����̬ѧ�б�
            %�˵�̫С�����
            filterIdx = [edgeStats.FilledArea] < 50 ;
            %���߱�
            w = bbox(:,3);
            h = bbox(:,4);
            aspectRatio = w./h;
            filterIdx = filterIdx | aspectRatio' > 8 ;
            filterIdx = filterIdx |  aspectRatio' <1/7 ;
            %��������̬ѧ�Ķ��˳���
            if  size(edgeStats,1)==length(find(filterIdx))
                continue
            end
            edgeStats(filterIdx) = [];
            clear filterIdx      
            %% ��5�� 1 pixel ����
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
            %���߱�
            w = bbox(:,3);
            h = bbox(:,4);
            aspectRatio = w./h;
            filterIdx = filterIdx | aspectRatio' > 8 ;
            filterIdx = filterIdx |  aspectRatio' <1/7 ;
            %��������̬ѧ�Ķ��˳���
            if  size(edgeStats,1)==length(find(filterIdx))
                continue
            end
            edgeStats(filterIdx) = [];
            clear filterIdx
            bbox = vertcat(edgeStats.BoundingBox);
            %% MSE��ȡ��proposals�õ��ˣ���������Ĵ֡�ϸ��λ����
            
            %% ��6���ı��з���+refine��2016-11-4��
            % �� [x y width height] �� [xmin ymin xmax ymax]
            xmin = bbox(:,1);
            ymin = bbox(:,2);
            xmax = xmin + bbox(:,3) - 1;
            ymax = ymin + bbox(:,4) - 1;
            % ��չbbox,ʹ��bbox���Ծۼ����ı���
            y_expansionAmount=0.01;
            ymin = (1-y_expansionAmount) * ymin;
            ymax = (1+y_expansionAmount) * ymax;
            x_expansionAmount=max(ceil(((ymax-ymin)-(xmax-xmin)+8)/2),ceil((ymax-ymin)/4));
            xmin = xmin-x_expansionAmount;
            xmax =xmax+x_expansionAmount;
            % bbox����ô��չ��Ҳ���ܳ���ԭͼ�ı߽�
            xmin = max(xmin, 1);
            ymin = max(ymin, 1);
            xmax = min(xmax, size(skeletImg,2));
            ymax = min(ymax, size(skeletImg,1));
            % 11-5:ȥ���ڲ�����̫���bbox����bbox�ܿ���������
            
            expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
            overlapRatio = bboxOverlapRatio(expandedBBoxes, expandedBBoxes,'ratioType','Min');
            % ��bbox�����Լ�û����ͨ��ϵ
            n = size(overlapRatio,1);
            overlapRatio(1:n+1:n^2) = 0;
            %�ҵ��ں�bbox���������bbox��ɾȥ
            overlap_index=zeros(1,n);
            for oi=1:n
                overlap_index(1,oi)=length(find(overlapRatio(oi,:)==1));
            end
            expandedBBoxes(find(overlap_index>10),:)=[];
            % ��չ���bbox�Ľ��չʾ
            afterExpend=insertShape(1-skeletImg, 'Rectangle', expandedBBoxes(:,1:4),'LineWidth',1,'Color','red');
            afterExpendNum=size(expandedBBoxes,1);
            if afterExpendNum==0
                continue
            end
            afterClassifierIdx=zeros(1,afterExpendNum);
            for ii=1:afterExpendNum
                text_str{ii} = num2str(ii);
                gBbox=g(expandedBBoxes(ii,2):expandedBBoxes(ii,2)+expandedBBoxes(ii,4)-1,expandedBBoxes(ii,1):expandedBBoxes(ii,1)+expandedBBoxes(ii,3)-1,:);
                save_gBname=[img_value '-bbox' num2str(ii)];
                score=runDetectorDemo_refine(gBbox,save_gBname);
                afterClassifierIdx(1,ii)=score;
            end
            afterExpend = insertText(afterExpend,expandedBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
            clear text_str
            save_name=[img_value '-txtLine-' num2str(i) '.bmp'];
            imwrite(afterExpend,save_name);          
            % 11-6 classifierǰ��Ա�
            expandedBBoxes(find(afterClassifierIdx==0),:)=[];
            %���˺�bbox�Ľ��չʾ
            afterClassifier=insertShape(1-skeletImg, 'Rectangle', expandedBBoxes(:,1:4),'LineWidth',1,'Color','red');
            afterClassifierNum=size(expandedBBoxes,1);
            if afterClassifierNum==0
                continue
            end
            for ii=1:afterClassifierNum
                text_str{ii} = num2str(ii);
            end
            afterClassifier = insertText(afterClassifier,expandedBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
            clear text_str
            save_name=[img_value '-afterClassifier-' num2str(i) '.bmp'];
            imwrite(afterClassifier,save_name);          
            
            %             overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
            %             % ��bbox�����Լ�û����ͨ��ϵ
            %             n = size(overlapRatio,1);
            %             overlapRatio(1:n+1:n^2) = 0;
            %             % Create the graph
            %             gh = graph(overlapRatio);
            %             % Find the connected text regions within the graph
            %             componentIndices = conncomp(gh);
            %             % Merge the boxes based on the minimum and maximum dimensions.
            %             xmin = accumarray(componentIndices', xmin, [], @min);
            %             ymin = accumarray(componentIndices', ymin, [], @min);
            %             xmax = accumarray(componentIndices', xmax, [], @max);
            %             ymax = accumarray(componentIndices', ymax, [], @max);
            %             % Compose the merged bounding boxes using the [x y width height] format.
            %             xmin( find(xmin~=1))=xmin( find(xmin~=1))+x_expansionAmount;
            %             xmax(find(xmax==size(skeletImg,2)))=xmax(find(xmax==size(skeletImg,2)))+x_expansionAmount;
            %             textBBoxes = [xmin ymin min(xmax-xmin+1-x_expansionAmount,size(skeletImg,2)-xmin) ymax-ymin+1];
            %% ��7����������
            %             addpath(genpath('/detectorDemo'));
            %             for ii=1:size(textBBoxes,1)
            %                 gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3),:);
            %                 score=runDetectorDemo_salient(gBbox);
            %                 if score>0
            %                     fusionBbox=[fusionBbox ; [textBBoxes(ii,:) score]];
            %                 end
            %             end
            %             clear textBBoxes
        end
        %% MSE+�ı���+classify�׶ν���
        
        %% ��8��fusion�׶Σ�
        %         if size(fusionBbox,1)==0
        %             continue
        %         end
        %         %     [fusionBbox, fusionBboxScore]=selectStrongestBbox(fusionBbox(:,1:4),fusionBbox(:,5),'RatioType','Min','OverlapThreshold',0.85);
        %         [fusionBbox, fusionBboxScore]=selectStrongestBbox(fusionBbox(:,1:4),fusionBbox(:,5));
        %         fusionBbox=[fusionBbox fusionBboxScore];
        %         fusionBboxName=[img_value '-fusion' '.mat'];
        %         save (fusionBboxName ,'fusionBbox' );
        %         % �����������������ֵ�Ľ��չʾ
        %         afterfusion = insertShape(g, 'Rectangle', fusionBbox(:,1:4),'LineWidth',1);
        %         afterfusionNum=size(fusionBbox,1);
        %         for ii=1:afterfusionNum
        %             text_str{ii} = num2str(fusionBbox(ii,5));
        %         end
        %         afterfusion = insertText(afterfusion,fusionBbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','red');
        %         clear text_str
        %         save_name=[img_value '-fusion' '.bmp'];
        %         imwrite(afterfusion,save_name);
    end %  if(~exist([img_value '-fusion.mat'], 'file'))������ͽ�����
    
    %% ��9��segment�׶Σ�
    %     load([img_value '-fusion.mat']);
    %     img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    %     g = imread(img_name);
    %     if size(fusionBbox,1)==0
    %         continue
    %     end
    %     for ii=1:size(fusionBbox,1)
    %        %��������segment�ɵ���
    %     end
    
end

