
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
%% 【1】检测子+分类器
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
load('initialSfIdx');
eIdx=[];
e10Idx=[];
for indexImg = 212:212
    fusionBBox=[];
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
        continue
    end
    %% 【2】文本行提取、验证、分割
    %【2.1】文本行初步构建成组
    % 从 [x y width height] 到 [xmin ymin xmax ymax]
    xmin = fusionBBox(:,1);
    ymin = fusionBBox(:,2);
    xmax = xmin + fusionBBox(:,3) - 1;
    ymax = ymin + fusionBBox(:,4) - 1;
    % bbox 不可以超过原图的边界
    xmin = max(xmin, 1);
    ymin = max(ymin, 1);
    xmax = min(xmax, size(g,2));
    ymax = min(ymax, size(g,1));
    expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
    % bbox作为结点，邻接关系作为边，建图
    %（1）将bbox构成文本行组的两个限制：height之比、偏移量
    overlapRatio = bboxOverlap(expandedBBoxes, expandedBBoxes);
    n = size(overlapRatio,1);
    overlapRatio(1:n+1:n^2) = 0;
    gh = graph(overlapRatio);
    % 在图中找出连通的文本区域
    componentIndices = conncomp(gh);
    % 构造refine用表：bbox序号，bbox中心点的横、纵坐标，bbox的高度
    refine_matrix=zeros(size(fusionBBox,1),3);
    refine_matrix(:,1)=fusionBBox(:,1)+fusionBBox(:,3)/2;
    refine_matrix(:,2)=fusionBBox(:,2)+fusionBBox(:,4)/2;
    refine_matrix(:,3)=fusionBBox(:,4);
    % 【2.2】intra:组内异常值的排除
    figure(1);
    axis([0 size(g,2) 0 size(g,1)]);
    set(gca, 'YDir','reverse');
    hold on
    intra_matrix=[];
    for i=1:max(componentIndices)
        txtGroup=find(componentIndices==i);
        %11-15：对txtGroup按横坐标重排序
        [~,I]=sort(refine_matrix(txtGroup,1));
        txtGroup=txtGroup(I);
        %
        %11-15-2: 在intra里发现异常值 : 角度、偏移、H之比
        intra_set=zeros(size(txtGroup,2),5);
        intra_set(1,1)=i;
        %
        for ii=1:size(txtGroup,2)
            j=txtGroup(1,ii);
            HY=refine_matrix(j,2)-refine_matrix(j,3)/2:refine_matrix(j,2)+refine_matrix(j,3)/2;
            HX=refine_matrix(j,1)*ones(1,length( HY));
            plot(HX,HY);
            if ii>1
                LY=[refine_matrix(txtGroup(1,ii-1),2) refine_matrix(j,2)];
                LX=[refine_matrix(txtGroup(1,ii-1),1) refine_matrix(j,1)];
                %11-15-2: 在intra里发现异常值 : 角度、偏移、H之比
                %（1）第几组
                intra_set(ii,1)=i;
                %（2）横坐标间距离
                intra_set(ii,2)=LX(2)-LX(1);
                %intra_set(ii,2)=sqrt((LX(2)-LX(1)).^2+(LY(2)-LY(1)).^2);
                %（3）角度
                intra_set(ii,3)=(LY(2)-LY(1))/(LX(2)-LX(1));
                %（4）偏移量
                yTop=max(LY(1)-refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)-refine_matrix(j,3)/2);
                yBottom=min(LY(1)+refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)+refine_matrix(j,3)/2);
                yH=max(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3));
                intra_set(ii,4)=abs(yBottom-yTop)/yH;
                %（5）H之比
                intra_set(ii,5)=min(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3))/yH;
                %
                plot(LX,LY,'-o',...
                    'LineWidth',0.5,...
                    'MarkerSize',2,...
                    'MarkerEdgeColor','b');
            end
            HY=[]; HX=[]; LY=[]; LX=[];
        end
        %重复值会造成干扰，去掉重复值
        
        if (isempty(find(intra_set(:,2)>10)))
            removeIdx=(1:size(intra_set,1))';
        else
            removeIdx=find(intra_set(:,2)<median(intra_set(intra_set(:,2)>10,2))/2);
        end
        
        intra_set(removeIdx,1)=i;
        intra_set(removeIdx,2)=0;intra_set(removeIdx,3)=0;intra_set(removeIdx,4)=0;intra_set(removeIdx,5)=0;
        intraH=figure(2);
        set(intraH,'name',['第' num2str(i) '组'],'Numbertitle','off');
        subplot(4,1,1);
        barX=1:size(txtGroup,2);
        bar(barX,intra_set(:,2)');
        title('距离');
        subplot(4,1,2);
        bar(barX,intra_set(:,3)');
        title('角度');
        subplot(4,1,3);
        bar(barX,intra_set(:,4)');
        title('偏移量');
        subplot(4,1,4);
        bar(barX,intra_set(:,5)');
        title('H之比');
        intra_matrix=[ intra_matrix ; intra_set];
        close figure 2
    end
    hold off
    close figure 1
    intraAll=figure(3);
    set(intraAll,'name',img_value,'Numbertitle','off');
    subplot(4,1,1);
    barX=1:size(intra_matrix,1);
    bar(barX,intra_matrix(:,2)');
    title('距离');
    subplot(4,1,2);
    bar(barX,intra_matrix(:,3)');
    title('角度');
    subplot(4,1,3);
    bar(barX,intra_matrix(:,4)');
    title('偏移量');
    subplot(4,1,4);
    bar(barX,intra_matrix(:,5)');
    title('H之比');
    saveas(gcf,[img_value  '-info.bmp']);
    close all
end


