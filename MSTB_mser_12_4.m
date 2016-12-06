
function mserBBoxes=MSTB_mser_12_4(img)
img = rgb2gray(img);
maxArea=round(size(img,1)*size(img,2)*0.2);
[mserRegions, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[50 maxArea],'ThresholdDelta',2);
%% Step 2: Remove Non-Text Regions Based On Basic Geometric Properties
% Use regionprops to measure MSER properties
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
% Compute the aspect ratio using bounding box data.
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
% Threshold the data to determine which regions to remove. These thresholds
% may need to be tuned for other images.
filterIdx = aspectRatio' > 1.5;
filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
filterIdx = filterIdx | [mserStats.Solidity] < .3;
filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
% Remove regions
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];
clear filterIdx
%% Step 4: Merge Text Regions For Final Detection Result
% Get bounding boxes for all the regions
bboxes = vertcat(mserStats.BoundingBox);
% [bboxes, ~]=selectStrongestBbox(bboxes(:,1:4),bboxes(:,3).*bboxes(:,4),'RatioType','Min','OverlapThreshold',0.9);
% xmin = bboxes(:,1);
% ymin = bboxes(:,2);
% xmax = xmin + bboxes(:,3) - 1;
% ymax = ymin + bboxes(:,4) - 1;
% % Expand the bounding boxes by a small amount.
% expansionAmount = 0.02;
% xmin = (1-expansionAmount) * xmin;
% xmax = (1+expansionAmount) * xmax;
% % Clip the bounding boxes to be within the image bounds
% xmin = max(xmin, 1);
% ymin = max(ymin, 1);
% xmax = min(xmax, size(img,2));
% ymax = min(ymax, size(img,1));
% % Show the expanded bounding boxes
% mserBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
[mserBBoxes, ~]=selectStrongestBbox(bboxes(:,1:4),bboxes(:,3).*bboxes(:,4),'RatioType','Min','OverlapThreshold',0.9);
end

