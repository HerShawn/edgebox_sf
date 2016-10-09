clc
clear
close all
% warning off all
addpath('piotr_toolbox');
addpath(genpath(pwd));

%% Parameters for EdgeBox
model=load('models/forest/modelBsds'); model=model.model;
model.opts.multiscale=0; model.opts.sharpen=2; model.opts.nThreads=4;
opts = edgeBoxes;
opts.alpha = .65;     % step size of sliding window search
opts.beta  = .75;     % nms threshold for object proposals
opts.minScore = .01;  % min score of boxes to detect
opts.maxBoxes = 1e4;  % max number of boxes to detect

%%
do_dir='C:\Users\Administrator\Desktop\制作数据集\';
dir_img = dir([do_dir 'Challenge2_Test_Task12_Images\*.jpg'] );
num_img = length(dir_img);

for indexImg = 33:num_img  
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);   
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);   
    [len,wid,~] = size(g);
    edgebox_hx=zeros(len,wid);
           
    tic, [bbs,E]=t_edgeBoxes(g,model,opts); toc
    b_num=length(bbs);
    bbs=bbs(1:min(1280,b_num),:);

    bbs=sortrows(bbs,-5);
      
    bbs(:,3)=bbs(:,1)+bbs(:,3);
    bbs(:,4)=bbs(:,2)+bbs(:,4);
%     weight=[];
    
%     for i=1:b_num
%         weight=[weight;(64/(8+(i-1)))];
%     end
    
    ser=1-E;

    for i=1:10:min(1280,b_num)
        
%         figure(1);imshow(1-E);
%          bbGt('showRes',ser,[bbs(i,1);bbs(i,2);bbs(i,3)-bbs(i,1);bbs(i,4)-bbs(i,2)]',[bbs(i,1);bbs(i,2);bbs(i,3)-bbs(i,1);bbs(i,4)-bbs(i,2)]');
%         edgebox_hx(bbs(i,2):bbs(i,4),bbs(i,1):bbs(i,3))=edgebox_hx(bbs(i,2):bbs(i,4),bbs(i,1):bbs(i,3))+weight(i,1);
        
         des = drawRect(ser,[bbs(i,1),bbs(i,2)],[bbs(i,3)-bbs(i,1),bbs(i,4)-bbs(i,2)],2 );
         ser=des;
        
         edgebox_hx(bbs(i,2):bbs(i,4),bbs(i,1):bbs(i,3))=edgebox_hx(bbs(i,2):bbs(i,4),bbs(i,1):bbs(i,3))+150/((bbs(i,3)-bbs(i,1)+bbs(i,4)-bbs(i,2))^1.5);
    end
    
    
    figure(indexImg);
    imshow(des);
    save_name=[img_value '.jpg'];
    print(indexImg,'-dpng', save_name);
    close; 
    


%     figure(indexImg);
    
%     figure(2);
%     imshow(1-E);
    
    figure(indexImg);
    [x,y]=meshgrid(1:1:wid,1:1:len);
    img_mesh=mesh(double(x),double(y),double(edgebox_hx));
    xlabel('x');
    ylabel('y');
    save_name=[img_value '-mesh.jpg'];
    print(indexImg, '-dpng', save_name);
%     imwrite(img_mesh,save_name);
    close; 
    
    
    row=sum(edgebox_hx,2);
    figure(indexImg);
    plot(row);
    save_name=[img_value '-row.jpg'];
    print(indexImg, '-dpng', save_name);
%     imwrite(img_plot,save_name);
    close; 
    
%     save_name=[img_value '.jpg'];
%     print(indexImg, '-dpng', save_name);
%     close all;
end