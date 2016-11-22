
function MSTB_mser_2(img,textBBoxes,img_value)
img = rgb2gray(img);
maxArea=round(size(img,1)*size(img,2)*0.2);
for ii=1:10
[mserRegions, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[50 maxArea],'ThresholdDelta',ii);
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
bbox = vertcat(mserStats.BoundingBox);
if isempty(bbox)
    continue
end
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
aftertext = insertShape(img, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','green');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','yellow');
figure
imshow(aftertext)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
title([num2str(length( find(textBBoxes(:,5)==1))) '-' num2str(length( find(textBBoxes(:,5)==2))) '-' num2str(length( find(textBBoxes(:,5)>2)))])
hold off
save_name=[img_value '-m-' num2str(ii) '.bmp'];
saveas(gcf,save_name);
close all
end
end
