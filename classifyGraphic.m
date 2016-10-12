
% 图形学判别
function [afterBBoxes,bbox]=classifyGraphic(skeletImg)

% 连通区域的属性
[L,num] = bwlabel(skeletImg,8);
mserStats = regionprops(L, 'BoundingBox', 'Area', ...
    'FilledArea','Extent' ,'ConvexArea','Image',...
    'EulerNumber','Solidity','Eccentricity','PixelList');

bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
bboxArea=w.*h;
%宽高比
filterIdx = aspectRatio' > 10 ;
filterIdx = filterIdx |  aspectRatio' <0.2 ;
%滤掉太小面积的
filterIdx = filterIdx | [mserStats.FilledArea] < 50 ;
filterIdx = filterIdx | [mserStats.ConvexArea]./bboxArea' < 0.5 ;
%欧拉数和（面积排在前两位）结合起来用
[~,index] = sortrows([mserStats.Area].');
thresh_Area=mserStats(index(end-2)).Area;
filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
%图形学和稳定性结合起来；存在上述情况，说明存在较严重的粘连情况，则直接跳到下一轮稳定性；
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

%图形学判别后的结果展示
afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
for ii=1:length(mserStats)
    text_str{ii} = num2str(ii);
end
length(mserStats);
afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');

end