
% 形态学判别
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
%宽高比
filterIdx = aspectRatio' > 7 ;
filterIdx = filterIdx |  aspectRatio' <1/7 ;
%滤掉太小面积的
filterIdx = filterIdx | [mserStats.FilledArea] <30  ;


%欧拉数和（面积排在前两位）结合起来用
% [~,index] = sortrows([mserStats.Area].');
% thresh_Area=mserStats(index(end-2)).Area;
% filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
%图形学和稳定性结合起来；存在上述情况，说明存在较严重的粘连情况，则直接跳到下一轮稳定性；

%

mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

%滤除掉内含bbox数目较多的边缘CC中
adjoin= bboxOverlapRatio(bbox, bbox,'Min');
% 设bbox与它自己没有连通关系
n = size(adjoin,1);
adjoin(1:n+1:n^2) = 0;
%计算每个bbox完全内含其它bbox的个数
adj_index=zeros(1,n);
for adj=1:n
    adj_index(1,adj)=length(find(adjoin(adj,:)==1));
end
%大于内含bbox数目中值的两倍的bbox在检测粘连点的考虑范围内
adj_thresh=max(1,median(adj_index))*7;
adjIdx=adj_index>adj_thresh;
mserStats(adjIdx)= [];
bbox = vertcat(mserStats.BoundingBox);


%图形学判别后的结果展示
afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
for ii=1:length(mserStats)
    text_str{ii} = num2str(ii);
end
length(mserStats);
afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');

end