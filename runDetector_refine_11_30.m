%% 11-29
function boxes=runDetector_refine_11_30(img,save_gBname,mserBBox,textIdx)
%% 
addpath(genpath('../finetune'));
load models/detectorCentroids_96.mat
load models/CNN-B256.mat
%% 计算响应，并由此得到字符位置，及单词分割线
fprintf('Constructing filter stack...\n');
filterStack = cstackToFilterStack(params, netconfig, centroids, P, M, [2,2,256]);
fprintf('Computing responses...\n');
[responses,scales] = computeResponses(img, filterStack);
boxes = findBoxesFull(responses,scales);
if isempty(boxes.bbox)
   return 
end
img=visualizeBoxes_11_29(img, boxes);
img = insertShape(img, 'Rectangle', mserBBox(:, 1:4),'LineWidth',1,'Color','yellow');
%% 显示
imshow(img);
imwrite(img,[save_gBname '-refine-' num2str(textIdx) '.bmp']);
imshow(img);
figure;
plot([responses{1,1}]);
zero_y=zeros(1,size(responses{1,1},2));
hold on
plot(1:size(responses{1,1},2),zero_y,'r');
hold off
fprintf('Finding lines...\n');
% score = findLinesFull_2016(responses);
saveas(gcf,[save_gBname '-response-' num2str(textIdx) '.bmp']); 
close all;
end

