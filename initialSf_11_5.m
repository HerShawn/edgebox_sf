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
initialSfIdx=zeros(1,num_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    E_tmp=E1;
    for i=1:1:30
        E1=E_tmp;
        %����Ӧ��ֵ�ָ�
        thresh=median(median(E1(find(E1>(i/100)))));
        E1(find(E1<thresh))=0;
        E1(find(E1>thresh))=1;
        % �Ǽ�ͼ: ��ͨ�ԡ��պ��Բ�����ʹ��Ե��ȱ�Ϊ1���ü��ͶϿ�ճ����
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
        %��߱�
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
        %% ��4�� ŷ����/ճ��������skelet������ֵ���ʺϣ�����
        if((length(find([edgeStats.EulerNumber] <= -10 ))>2)||(length(edgeStats)>150))
            continue;
        end
        initialSfIdx(1,indexImg)=i;
        break
    end
end
