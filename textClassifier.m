function score=textClassifier(img)

addpath(genpath('../finetune'));

load models/refine_classifier_cnn.mat

fprintf('Constructing filter stack...\n');
filterStack = cstackToFilterStack(params, netconfig, centroids, P, M, [2,2,256]);

fprintf('Computing responses...\n');

[responses,~] = computeResponses(img, filterStack);


posRatio=length( find([responses{1,1}]>0))/size(responses{1,1},2);
if posRatio<0.3
    score=0;
else
    score=1;
end                                              

end


