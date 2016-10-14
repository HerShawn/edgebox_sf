
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
for indexImg = 157:157
    
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %% ��1���ȶ��� MSTB: Maximal Stable Text Boundary ���ȶ������ֱ�Ե
    for i=5:1:30
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
        binaryzation =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        edgeNum=length(edgeStats);
        for ii=1:edgeNum
            text_str{ii} = num2str(ii);
        end
        binaryzation = insertText(binaryzation,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-binaryzation-' num2str(edgeNum) '.bmp'];
        imwrite(1-binaryzation,save_name);
                
        %% ��2����̬ѧ�б�
         
        %��߱�
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        bboxArea=w.*h;
        filterIdx = aspectRatio' > 10 ;
        filterIdx = filterIdx |  aspectRatio' <0.2 ;
        %�˵�̫С�����
        filterIdx = filterIdx | [edgeStats.FilledArea] < 50 ;
             
        %ŷ�����ͣ��������ǰ��λ�����������
        [~,index] = sortrows([edgeStats.Area].');
        thresh_Area=edgeStats(index(end-2)).Area;
        %��̬ѧ���ȶ��Խ���������������������˵�����ڽ����ص�ճ���������ֱ��������һ����ֵ�ָ
        if(~isempty(find(([edgeStats.EulerNumber] <= -10 )&([edgeStats.Area]>=thresh_Area))))
            continue;
        end
       
        %��������̬ѧ�Ķ��˳���    
        edgeStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(edgeStats.BoundingBox);
        
        %ͼ��ѧ�б��Ľ��չʾ
        afterMorphology =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
        afterMorphologyEdgeNum=length(edgeStats);
        for ii=1:afterMorphologyEdgeNum
            text_str{ii} = num2str(ii);
        end
        afterMorphology = insertText(afterMorphology,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        clear text_str
        save_name=[img_value '-' num2str(i) '-afterMorphology-' num2str(afterMorphologyEdgeNum) '.bmp'];
        imwrite(1-afterMorphology,save_name);
        
        %% ��3��ճ�����⼰�Ͽ� ���պ��ԣ��ں�bbox��Ŀ
        
        %ճ��ֻ���ܷ����ڱպϱ�ԵCC��
        closure=zeros(1,afterMorphologyEdgeNum);
        for ii=1:afterMorphologyEdgeNum
            closure = edgeStats(ii).FilledArea/edgeStats(ii).Area;
        end
        filterIdx = closure == 1 ;
        edgeStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);
        
        %ճ���ܿ��ܷ������ں�bbox��Ŀ�϶�ı�ԵCC��
        adjoin= bboxOverlapRatio(bbox, bbox,'Min');
        % ��bbox�����Լ�û����ͨ��ϵ
        n = size(adjoin,1);
        adjoin(1:n+1:n^2) = 0;
        %����ÿ��bbox��ȫ�ں�����bbox�ĸ���
        adj_index=zeros(1,n);
        for adj=1:n
            adj_index(1,adj)=length(find(adjoin(adj,:)==1));
        end
        %�����ں�bbox��Ŀ��ֵ��������bbox�ڼ��ճ����Ŀ��Ƿ�Χ��
        adj_thresh=max(1,median(adj_index))*2;
        adjIdx=adj_index>adj_thresh;
        adjStats=edgeStats(adjIdx);
        
        
    end   
end
