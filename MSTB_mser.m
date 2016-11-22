
function MSTB_mser(img,textBBoxes,img_value)
%% Step 1: Detect Candidate Text Regions Using MSER
img = rgb2gray(img);
[mserRegions, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[50 8000],'ThresholdDelta',2);

% figure
% imshow(img)
% hold on
% plot(mserRegions, 'showPixelList', true,'showEllipses',false)
% title('MSER regions')
% hold off


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
filterIdx = aspectRatio' > 7;
filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
filterIdx = filterIdx | [mserStats.Solidity] < .3;
filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] < -4;

% Remove regions
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];
clear filterIdx

% Show remaining regions
% figure
% imshow(img)
% hold on
% plot(mserRegions, 'showPixelList', true,'showEllipses',false)
% title('After Removing Non-Text Regions Based On Geometric Properties')
% hold off


%% Step 3: Remove Non-Text Regions Based On Stroke Width Variation
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

% Show remaining regions
aftertext = insertShape(img, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','green');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','yellow');
figure
imshow(aftertext)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
title([num2str(length( find(textBBoxes(:,5)==1))) '-' num2str(length( find(textBBoxes(:,5)==2))) '-' num2str(length( find(textBBoxes(:,5)==1)))])
hold off

save_name=[img_value '-txt' '.bmp'];
saveas(gcf,save_name);

close all
end
