
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
load('initialSfIdx');
eIdx=[];
e10Idx=[];
fusionBBox=[];

for indexImg = 36:36
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E1=edgesDetect(g,t_model);
    E_tmp=E1;
    %自适应的设置起始阈值分割起始
    E_thresh=initialSfIdx(1,indexImg);
    E_thresh2=median(median(E1(find(E1>0))));
    E_thresh2= round(100*median(median(E1(find(E1>E_thresh2)))));
    E_thresh=max(E_thresh,E_thresh2);
    
    if(exist([img_value '-' num2str(E_thresh) '.mat'], 'file'))
        load([img_value '-' num2str(E_thresh) '.mat']);
        fusionBBox=[fusionBBox; expandedBBoxes];
        expandedBBoxes=[];
    else
        eIdx=[eIdx indexImg];
    end
    
    if(exist([img_value '-' num2str(E_thresh+10) '.mat'], 'file'))
        load([img_value '-' num2str(E_thresh+10) '.mat']);
        fusionBBox=[fusionBBox; expandedBBoxes];
        expandedBBoxes=[];
    else
        e10Idx=[e10Idx indexImg];
    end
    
    if((~exist([img_value '-' num2str(E_thresh) '.mat'], 'file'))&&(~exist([img_value '-' num2str(E_thresh+10) '.mat'], 'file')))
        fusionBBox=[];
        continue
    end
    
    %构造refine用表，包含4项重要信息：bbox序号，bbox中心点的横、纵坐标，bbox的高度（可作为与别的bbox进行匹配的一种特征）
    refine_matrix=zeros(size(fusionBBox,1),3);
    refine_matrix(:,1)=fusionBBox(:,1)+fusionBBox(:,3)/2;
    refine_matrix(:,2)=fusionBBox(:,2)+fusionBBox(:,4)/2;
    refine_matrix(:,3)=fusionBBox(:,4);
    fusionBBox=[];
    
    %refine_matrix的可视化，将4项重要信息都表现出来
    subplot(1,2,1);
    axis([0 size(g,2) 0 size(g,1)]);
    %     axis equal;
    set(gca, 'YDir','reverse');
    set(gca, 'XAxisLocation','top');
    hold on
    grid minor
    for ii=1:size(refine_matrix,1)
        refineY=refine_matrix(ii,2)-refine_matrix(ii,3)/2:refine_matrix(ii,2)+refine_matrix(ii,3)/2;
        refineX=refine_matrix(ii,1)*ones(1,length(refineY));
        plot(refineX,refineY);
        %textY=min(refine_matrix(ii,2)+refine_matrix(ii,3)/2,size(g,1));
        %text(refine_matrix(ii,1),textY,num2str(ii),'FontSize',6);
    end
    hold off
    
    %line
    subplot(1,2,2);
    tbl=tabulate(refine_matrix(:,2)');
    same_num=length( find(tbl(:,2)>1));
    if same_num>0
        same_table=zeros(length( find(tbl(:,2)>1)),2);
        same_table(:,1)=tbl( find(tbl(:,2)>1),1);
        same_table(:,2)=tbl( find(tbl(:,2)>1),2);
        %消除重复的算法，是给相同的横坐标+0.001*j
        for i=1:size(same_table,1)
            refineIdx=find(refine_matrix(:,2)==same_table(i,1));
            for j=1:same_table(i,2)
                refine_matrix(refineIdx(j,1),2)=refine_matrix(refineIdx(j,1),2)+0.001*j;
            end
        end
    end
    %用横向barh图画出bbox的特征表达
    refine_handle=barh(refine_matrix(:,2)',refine_matrix(:,3)','EdgeColor','r');
    axis([0 max(refine_matrix(:,3)) 0 size(g,1)]);
    set(gca, 'YDir','reverse');
    
    saveas(gcf,[img_value  '.bmp']);
    close all
end


