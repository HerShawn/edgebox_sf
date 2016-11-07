function score=runDetectorDemo_refine(img,save_gBname)

addpath(genpath('../finetune'));

%2016-10-25
% load first layer features
load models/detectorCentroids_96.mat
% load detector model
load models/CNN-B256.mat
% load models/cnn_refine.mat

fprintf('Constructing filter stack...\n');
filterStack = cstackToFilterStack(params, netconfig, centroids, P, M, [2,2,256]);

fprintf('Computing responses...\n');

[responses,scales] = computeResponses(img, filterStack);


% 11-6
posRatio=length( find([responses{1,1}]>0))/size(responses{1,1},2);
if posRatio<0.5
%     fusionBbox(fusionBboxIdx,:)=[];
    score=0;
    return 
end    

fprintf('Finding lines...\n');
score = findLinesFull_2016(responses);

save_name=[save_gBname  '.png'];
imwrite(img,save_name);


