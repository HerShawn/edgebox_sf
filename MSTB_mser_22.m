
function bboxes=MSTB_mser_22(img)
img = rgb2gray(img);
maxArea=round(size(img,1)*size(img,2)*0.2);
bboxes=[];
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
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);
bboxes=[bboxes;bbox];
end
end
