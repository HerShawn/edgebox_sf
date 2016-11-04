function score=runDetectorDemo_refine(img,save_gBname)

addpath(genpath('../finetune'));

%2016-10-25
% load first layer features
load models/detectorCentroids_96.mat
% load detector model
load models/CNN-B256.mat

fprintf('Constructing filter stack...\n');
filterStack = cstackToFilterStack(params, netconfig, centroids, P, M, [2,2,256]);

fprintf('Computing responses...\n');
h=figure;
subplot(2,1,1);imshow(img);
[responses,scales] = computeResponses(img, filterStack);
subplot(2,1,2);
plot([responses{1,1}]);
zero_y=zeros(1,size(responses{1,1},2));
hold on
plot(1:size(responses{1,1},2),zero_y,'r');
hold off
fprintf('Finding lines...\n');
%boxes = findBoxesFull(responses,scales);
score = findLinesFull_2016(responses);
set(h,'name',num2str(score));
% visualizeBoxes(img, boxes,save_gBname);
saveas(h,[save_gBname '-score' num2str(score) '.jpg']); 
close all;

% if exist('outputDir')
%   system(['mkdir -p ', outputDir]);
%   save([outputDir, '/output.mat'], 'filterStack', 'responses', 'boxes', '-v7.3');
% end
