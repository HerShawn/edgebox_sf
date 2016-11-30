
function mserBBoxe=textMser(gBbox)
img = rgb2gray(gBbox);
maxArea=ceil(size(img,1)*size(img,1)*9/16);
minArea=round(maxArea/25);
bboxes=[];
% 为提高mser检出率，将阈值从1到10递增（以后试下多通道的方式）
for jj=1:10
    [~, mserConnComp] = detectMSERFeatures(img, ...
        'RegionAreaRange',[minArea maxArea],'ThresholdDelta',jj);
    mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');
    bbox = vertcat(mserStats.BoundingBox);
    if isempty(bbox)
        continue
    end
    w = bbox(:,3);
    h = bbox(:,4);
    aspectRatio = w./h;
    filterIdx = aspectRatio' > 1.5;
    filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
    filterIdx = filterIdx | [mserStats.Solidity] < .3;
    filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
    filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
    filterIdx = filterIdx |  h'./size(gBbox,1)>0.9;
    mserStats(filterIdx) = [];
    clear filterIdx
    bbox = vertcat(mserStats.BoundingBox);
    bboxes=[bboxes;bbox];
end
if isempty(bboxes)
    mserBBoxe=[];
else
[mserBBoxe, ~]=selectStrongestBbox(bboxes(:,1:4),bboxes(:,3).*bboxes(:,4),'RatioType','Min','OverlapThreshold',0.8);
end
end
