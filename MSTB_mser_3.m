

function MSTB_mser_3(g,textBBoxes,img_value)
addpath (genpath('export_fig'))

textBBoxesNum=size(textBBoxes,1);
for ii=1:textBBoxesNum
gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3)-1,:);
img = rgb2gray(gBbox);
maxArea=round(size(img,1)*size(img,2)*0.2);
[mserRegions, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[50 maxArea],'ThresholdDelta',2);
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
filterIdx = aspectRatio' > 7;
filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
filterIdx = filterIdx | [mserStats.Solidity] < .3;
filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
% Remove regions
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];
clear filterIdx

% Threshold the stroke width variation metric
strokeWidthThreshold = 0.4;
% Process the remaining regions
for j = 1:numel(mserStats)   
    regionImage = mserStats(j).Image;
    regionImage = padarray(regionImage, [1 1], 0);      
    distanceImage = bwdist(~regionImage);  
    skeletonImage = bwmorph(regionImage, 'thin', inf);
    strokeWidthValues = distanceImage(skeletonImage);
    strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
    strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold; 
end
% Remove regions based on the stroke width variation
mserRegions(strokeWidthFilterIdx) = [];
mserStats(strokeWidthFilterIdx) = [];
clear strokeWidthFilterIdx

figure
imshow(img);
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
hold off
save_name=[img_value '-' num2str(ii) '.bmp'];
export_fig (gcf,save_name);
close all
end
end
