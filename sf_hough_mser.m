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
do_dir='D:\edgebox-contour-neumann���ּ�ⷽ���ıȽ�\';
dir_img = dir([do_dir 'Challenge2_Test_Task12_Images\*.jpg']);
num_img = length(dir_img);
for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    E=edgesDetect(g,model);
    F=imresize(E,[640,NaN]);
    G=im2bw(F,0.1);
    
    [H, theta, rho] = hough(G, 'RhoResolution',0.4 ,'Theta', -90);
    P = houghpeaks(H, 30 ,'threshold',ceil(0.2*max(H(:))));
    lines = houghlines(G, theta, rho, P,'FillGap',10,'MinLength',7);
    
%     imshow(G);hold on
%     for k = 1: length(lines)
%         xy = [lines(k).point1; lines(k).point2];
%         plot(xy(:, 1), xy(:, 2), 'LineWidth', 4, 'Color','green');
%         plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
%         plot(xy(2,1),xy(2,2),'x','LineWidth',4,'Color','red');
%     end
%     hold off
%     save_name=[img_value '.jpg'];
%     print(gcf, '-dpng', save_name);
%     close all

    
  
    %% SF  im2bw  cc
    G=im2bw(F,0.2);
    img2 =bwareaopen(G,6,8);       %���հ���ͨ���򣬽����С��6����ͨ�����˳���
    [L,num] = bwlabel(img2,8);      % ����img2�İ���ͨ����LΪ���صĴ����ͼ�񣬳ߴ���img2��ͬ��numΪ��ͨ������Ŀ�� 
    % PS��������̬ѧ�˲����룺 
    SE1=strel('square',3);  
    img2= imerode(img2,SE1,'same');
    img2=imdilate(img2,SE1,'same');
    %          Ȼ�󣬾�Ҫ����ͬ����ͨ�����ò�ͬ����ɫ��ʶ������    
    [m,n] = size(img2);  
    img_color = zeros(m,n,3);   % ��ʾͼ����ͨ���� 
    img_color_tmp =reshape(img_color,m*n,3);  % ���ɶ�ά�ģ�����find��������Ϊfind�ҵ���һά�������±ꣻ   
    %% Ϊ����ɫ��ʾ���ӷḻ���ҵ�����4����ɫģ�飬ÿһ����ʾ64����ɫ��(�ɲο��ղص�CSDN���ͣ��и������ɫģ����Ϣ)   
    color_map1 = colormap(cool(64));     % ��ɫģ��1 
    color_map2 = colormap(hot(64));     % ��ɫģ��2  
    color_map3 = colormap(hsv(64));     % ��ɫģ��3  
    color_map4 = colormap(pink(64));     % ��ɫģ��4  
    color_map =[color_map1;color_map2;color_map3;color_map4];        % ����ɫģ��ƴ������������һ��256����ɫ��color_map������Ϊ��ͨ������ĿС��256��   
    power = floor(256/num);     % ��Ȩ��Ϊ�˽���ɫ���ֵĸ���������Ļ���ɫ̫�ӽ�����ʾ�������
    if power==0
        power=1
        num=255
    end
    for i = 1:1:num       
        img_color_tmp(find(L == i),1)= color_map(i*power,1);   
        img_color_tmp(find(L == i),2)= color_map(i*power,2);  
        img_color_tmp(find(L == i),3)= color_map(i*power,3);   
        img_color =reshape(img_color_tmp, m, n, 3);   
    end
    hold on
    figure(indexImg),imagesc(img_color), hold on  % ��ʾͼ��
%     figure(indexImg)
    for k = 1: length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:, 1), xy(:, 2), 'LineWidth', 4, 'Color','green');
        plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
        plot(xy(2,1),xy(2,2),'x','LineWidth',4,'Color','red');
    end
    hold off
    save_name=[img_value '.jpg'];
    print(gcf, '-dpng', save_name);
    close all
end

