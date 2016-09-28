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
tic, model=edgesTrain(opts); toc; % will load model if already trained
%% set detection parameters (can set after training)
model.opts.multiscale=0;          % for top accuracy set multiscale=1
model.opts.sharpen=2;             % for top speed set sharpen=0
model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
model.opts.nThreads=4;            % max number threads for evaluation
model.opts.nms=0;                 % set to true to enable nms
%% evaluate edge detector on BSDS500 (see edgesEval.m)
if(0), edgesEval( model, 'show',1, 'name','' ); end
%% detect edge and visualize results
do_dir='D:\edgebox-contour-neumann三种检测方法的比较\';
dir_img = dir([do_dir 'Challenge2_Test_Task12_Images\*.jpg']);
num_img = length(dir_img);
for indexImg = 124:124
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E=edgesDetect(g,model);
    F=imresize(E,[640,NaN]);    
    %2016-7-20
%     [len,wid,~] = size(1-F);
%     [x,y]=meshgrid(1:1:wid,1:1:len);   
%     mesh(double(x),double(y),double(F));    
    %
    for num=1:1
    G=im2bw(F,0.1*num);    
    [H, theta, rho] = hough(G, 'RhoResolution',0.4,'Theta', -90);
    %     ,'Theta', [-40:0.5:-15,15:0.5:40]
    %     figure
    %     imshow(H, [],'Xdata', theta, 'Ydata', rho, 'InitialMagnification','fit');
    %     xlabel('\theta'), ylabel('\rho');
    %     axis on, axis normal
    P = houghpeaks(H, 30 ,'threshold',ceil(0.2*max(H(:))));
    %     %     ,'threshold',ceil(0.3*max(H(:)))
    %     hold on
    %     plot(theta(P(:, 2)), rho(P(:, 1)), 'linestyle', 'none', 'marker', 's', 'color', 'w')
    lines = houghlines(G, theta, rho, P,'FillGap',10,'MinLength',7);
    h=figure(num),imshow(G, []), hold on   
    %% 2016.7.19 应该对lines中的数据做下预处理
    %     %先不要管时间性能和代码繁琐，先把功能实现：
    %         %【1】只考虑水平的特征线段 （补：以及竖直的线段）
    %         lines_index=zeros(1,length(lines));
    %         for i=1:length(lines)
    %             if (lines(i).theta==-90||lines(i).theta==0)
    %                 lines_index(1,i)=1;
    %             end
    %         end
    %         lines=lines(lines_index==1);
    %     %【2】分行
    %     lines(1).theta=1;
    %     lines(1).rho=lines(1).point2(2);
    %     flat=1;
    %     for i=2:length(lines)
    %         if (lines(i).point2(2)-lines(i-1).point2(2)==0)
    %             lines(i).theta= flat;
    %         else
    %             flat=flat+1;
    %             lines(i).theta= flat;
    %         end
    %         lines(i).rho=lines(i).point2(2);
    %     end
    %
    %     lines_index2=zeros(1,length(lines));
    %     for i=1:lines(end).theta
    %         if( length( find([lines.theta]'==i))>4)
    %          lines_index2([find([lines.theta]'==i)]')=1;
    %         end
    %     end
    %      lines=lines(lines_index2==1);
    %%   
    %for  k = 1: length(lines)
    for k = 1: length(lines)
        % 2016.7.19  应该在这里加入判断条件：是否该引入当前line        
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:, 1), xy(:, 2), 'LineWidth', 4, 'Color','green');
        plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
        plot(xy(2,1),xy(2,2),'x','LineWidth',4,'Color','red');
    end
        save_name=[img_value '-' num2str(num) '.jpg'];
        print(h, '-dpng', save_name);
        close
    end
    %     for i=1:length(lines)
    %         [B,I]=sort(lines(i).point2(2));
    %     end
end
