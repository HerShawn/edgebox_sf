%% 2016-10-20
%MSE的recall与imprecision
function MSE_eval()
clear
clc


dir_es = dir('C:\Users\Administrator\Desktop\制作数据集\estimate2\*.txt');
num_img = length(dir_es);
es_num=0;
gt_num=0;

es_imp=0;
gt_imp=0;

% max_t = zeros(5,12);

        for index = 1:num_img
%             gt_name = ['E:\2012 文字检测\测试集\ICDAR 2011\test-textloc-gt\gt_' dir_es(index).name];
            gtImgName=dir_es(index).name;
            gt_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task1_GT\gt_' gtImgName(1:end-7) '.txt'];
%             es_name = ['E:\2013毕设文字检测\试验结果\一起训练\location13\' dir_es(index).name];
            es_name = ['C:\Users\Administrator\Desktop\制作数据集\estimate2\' dir_es(index).name ];
            % 读groundtruth坐标
            fid = fopen(gt_name);
            txt_data = textscan(fid,'%d,%d,%d,%d,%s');
            fclose(fid);
            num_gt = length(txt_data{2});
            lc_gt = zeros(num_gt,4);
            for i = 1:num_gt
                lc_gt(i,1) = txt_data{1}(i);
                lc_gt(i,2) = txt_data{2}(i);
                lc_gt(i,3) = txt_data{3}(i)-txt_data{1}(i);
                lc_gt(i,4) = txt_data{4}(i)-txt_data{2}(i);
            end
            %     lc_gt = dlmread(gt_name);
            % 读估计坐标
            %     fid = fopen(es_name);
            %     txt_data = textscan(fid,'%d,%d,%d,%d');
            %     if ~~isempty(txt_data{1})
            %         fclose(fid);
            %         continue
            %     end
            %     lc_es =  dlmread(es_name);
            fid = fopen(es_name);
            txt_data = textscan(fid,'%d,%d,%d,%d');
            fclose(fid);
            num_es = length(txt_data{2});
            lc_es = zeros(num_es,4);
            for i = 1:num_es
                lc_es(i,1) = txt_data{1}(i);
                lc_es(i,2) = txt_data{2}(i);
                lc_es(i,3) = txt_data{3}(i);
                lc_es(i,4) = txt_data{4}(i);
            end
           
            es_imp=es_imp+num_es;
            gt_imp=gt_imp+num_gt;
            each_imprecison=num_es/num_gt
            
            adjoin= bboxOverlapRatio(lc_gt, lc_es);
            n = size(adjoin,1);
            adj_index=zeros(1,n);
            for adj=1:n
                adj_index(1,adj)=length(find(adjoin(adj,:)>0.02));
            end
            
            each_recall=length( find(adj_index))/num_gt
            
            es_num=es_num+length( find(adj_index));
            gt_num=gt_num+num_gt;
            
        end
        total_recall=es_num/gt_num
        total_impresion=es_imp/gt_imp
end