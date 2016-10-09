% Demo for Structured Edge Detector (please see readme.txt first).
close all
clear
clc
addpath('piotr_toolbox');
addpath(genpath(pwd));
%% set opts for training (see edgesTrain.m)
opts=edgesTrain();                % default options (good settings)
opts.modelDir='models/';          % model will be in models/forest
opts.modelFnm='modelBsds';        % model name
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
opts.useParfor=0;                 % parallelize if sufficient memory
%% train edge detector (~20m/8Gb per tree, proportional to nPos/nNeg)
opts.nPos=5e5; opts.nNeg=5e5;     % decrease to speedup training
t_model=t_edgesTrain(opts);
%% set detection parameters (can set after training)
t_model.opts.multiscale=0;          % for top accuracy set multiscale=1
t_model.opts.sharpen=2;             % for top speed set sharpen=0
t_model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
t_model.opts.nThreads=4;            % max number threads for evaluation
t_model.opts.nms=0;                 % set to true to enable nms
%% detect edge and visualize results
dir_img = dir('C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 157:157
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    
    %�ȶ��� MSTB: Maximal Stable Text Boundary ���ȶ������ֱ�Ե
    for i=5:2:19 
       
        %����Ӧ��ֵ�ָ�
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
          
        %�ı��з���֮һ����ɫ������
%         g=sfMask(g,E1);
%         figure(1);imshow(g);
              
        %��ͨ�������
        [L,num] = bwlabel(E1,8);
        mserStats = regionprops(L, 'BoundingBox', 'Area', ...
            'FilledArea','Extent' ,'ConvexArea',...
            'EulerNumber','Solidity','Eccentricity');
        
        %ͼ��ѧ�б�
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
        filterIdx = filterIdx | ([mserStats.EulerNumber] < -10 )&([mserStats.Area]>=thresh_Area);
        mserStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);   
        
        % ��ͨ�����ע
        afterBBoxes = insertShape(double(E1),'Rectangle',bbox,'LineWidth',1);
        for ii=1:length(mserStats)
            text_str{ii} = num2str(ii);
        end
        length(mserStats)
        afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');
        figure(2);imshow(1-afterBBoxes);       
        clear text_str
        E1=E_tmp;
        
        %������ͼ��
        save_name=[img_value '-' num2str(i) '-' num2str(length(mserStats)) '.bmp'];
        imwrite(1-afterBBoxes,save_name);
    end
    
end
