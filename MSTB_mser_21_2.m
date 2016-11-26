%% ÕûÍ¼mser£»±Ê»®¿í¶È£»strong¡¢weak¡¢false£»
function MSTB_mser_21_2(img,textBBoxes,img_value)
img = rgb2gray(img);
maxArea=round(size(img,1)*size(img,2)*0.2);
bboxes=[];
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
mserStats(strokeWidthFilterIdx) = [];
bbox = vertcat(mserStats.BoundingBox);
bboxes=[bboxes;bbox];
clear strokeWidthFilterIdx
end
aftertext = insertShape(img, 'Rectangle', bboxes,'LineWidth',1,'Color','cyan');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
save_name=[img_value '-stroke-' num2str(ii) '.bmp'];
imwrite(aftertext,save_name);
end
