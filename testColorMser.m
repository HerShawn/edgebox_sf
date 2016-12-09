
function testColorMser(colorImg)
[mserRegions, mserConnComp] = detectMSERFeatures(colorImg, ...
    'RegionAreaRange',[50 8000],'ThresholdDelta',2);
figure;
subplot(1,2,1);
imshow(colorImg)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
hold off
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
filterIdx = aspectRatio' > 2;
% filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
% filterIdx = filterIdx | [mserStats.Solidity] < .3;
% filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
% filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];
clear filterIdx
subplot(1,2,2);
imshow(colorImg)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
hold off
end