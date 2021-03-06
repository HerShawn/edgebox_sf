
function MSTB_mser_2_2(img,textBBoxes,img_value)
img = rgb2gray(img);
maxArea=round(size(img,1)*size(img,2)*0.2);
for ii=1:10
[mserRegions, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[50 maxArea],'ThresholdDelta',ii);
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
if numel(mserStats)<2
    continue
end
strokeWidthThreshold = 0.4;
for j = 1:numel(mserStats)
    regionImage = mserStats(j).Image;
    regionImage = padarray(regionImage, [1 1], 0);
    distanceImage = bwdist(~regionImage);    
    skeletonImage = bwmorph(regionImage, 'thin', inf);    
    strokeWidthValues = distanceImage(skeletonImage);   
    strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);   
    strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;    
end
mserRegions(strokeWidthFilterIdx) = [];
mserStats(strokeWidthFilterIdx) = [];
clear strokeWidthFilterIdx
aftertext = insertShape(img, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','green');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','yellow');
figure
imshow(aftertext)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
title([num2str(length( find(textBBoxes(:,5)==1))) '-' num2str(length( find(textBBoxes(:,5)==2))) '-' num2str(length( find(textBBoxes(:,5)>2)))])
hold off
save_name=[img_value '-s-' num2str(ii) '.bmp'];
saveas(gcf,save_name);
close all
end
end
