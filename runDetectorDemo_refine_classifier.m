function score=runDetectorDemo_refine_classifier(img,save_gBname)

addpath(genpath('../finetune'));

%2016-10-25
% % load first layer features
% load models/detectorCentroids_96.mat
% % load detector model
% load models/CNN-B256.mat
%2016-10-28
%2016-11-1
load models/cnn_refine.mat
load models/detectorCentroids_96.mat

fprintf('Constructing filter stack...\n');
filterStack = cstackToFilterStack(params, netconfig, centroids, P, M, [2,2,256]);

fprintf('Computing responses...\n');

[responses,~] = computeResponses(img, filterStack);

%2016-10-26 

%ÏÔÊ¾
h=figure;
subplot(2,1,1);imshow(img);
subplot(2,1,2);
plot([responses{1,1}]);
zero_y=zeros(1,size(responses{1,1},2));
hold on
plot(1:size(responses{1,1},2),zero_y,'r');
hold off

% posRatio=length( find([responses{1,1}]>0))/size(responses{1,1},2);
% if posRatio<0.5
% %     fusionBbox(fusionBboxIdx,:)=[];
%     score=0;
%     close all;
%     return 
% end


fprintf('Finding lines...\n');

score = findLinesFull_2016(responses);

set(h,'name',num2str(score));
saveas(h,[save_gBname '-score' num2str(score) '.jpg']); 
close all;

