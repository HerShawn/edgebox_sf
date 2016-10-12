
% ͼ��ѧ�б�
function [afterBBoxes,bbox]=classifyGraphic(skeletImg)

% ��ͨ���������
[L,num] = bwlabel(skeletImg,8);
mserStats = regionprops(L, 'BoundingBox', 'Area', ...
    'FilledArea','Extent' ,'ConvexArea','Image',...
    'EulerNumber','Solidity','Eccentricity','PixelList');

bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
bboxArea=w.*h;
%��߱�
filterIdx = aspectRatio' > 10 ;
filterIdx = filterIdx |  aspectRatio' <0.2 ;
%�˵�̫С�����
filterIdx = filterIdx | [mserStats.FilledArea] < 50 ;
filterIdx = filterIdx | [mserStats.ConvexArea]./bboxArea' < 0.5 ;
%ŷ�����ͣ��������ǰ��λ�����������
[~,index] = sortrows([mserStats.Area].');
thresh_Area=mserStats(index(end-2)).Area;
filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
%ͼ��ѧ���ȶ��Խ���������������������˵�����ڽ����ص�ճ���������ֱ��������һ���ȶ��ԣ�
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

%ͼ��ѧ�б��Ľ��չʾ
afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
for ii=1:length(mserStats)
    text_str{ii} = num2str(ii);
end
length(mserStats);
afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');

end