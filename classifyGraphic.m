
% ��̬ѧ�б�
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
%��߱�
filterIdx = aspectRatio' > 7 ;
filterIdx = filterIdx |  aspectRatio' <1/7 ;
%�˵�̫С�����
filterIdx = filterIdx | [mserStats.FilledArea] <30  ;


%ŷ�����ͣ��������ǰ��λ�����������
% [~,index] = sortrows([mserStats.Area].');
% thresh_Area=mserStats(index(end-2)).Area;
% filterIdx = filterIdx | ([mserStats.EulerNumber] <= -10 )&([mserStats.Area]>=thresh_Area);
%ͼ��ѧ���ȶ��Խ���������������������˵�����ڽ����ص�ճ���������ֱ��������һ���ȶ��ԣ�

%

mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

%�˳����ں�bbox��Ŀ�϶�ı�ԵCC��
adjoin= bboxOverlapRatio(bbox, bbox,'Min');
% ��bbox�����Լ�û����ͨ��ϵ
n = size(adjoin,1);
adjoin(1:n+1:n^2) = 0;
%����ÿ��bbox��ȫ�ں�����bbox�ĸ���
adj_index=zeros(1,n);
for adj=1:n
    adj_index(1,adj)=length(find(adjoin(adj,:)==1));
end
%�����ں�bbox��Ŀ��ֵ��������bbox�ڼ��ճ����Ŀ��Ƿ�Χ��
adj_thresh=max(1,median(adj_index))*7;
adjIdx=adj_index>adj_thresh;
mserStats(adjIdx)= [];
bbox = vertcat(mserStats.BoundingBox);


%ͼ��ѧ�б��Ľ��չʾ
afterBBoxes =insertShape(skeletImg,'Rectangle',bbox,'LineWidth',1);
for ii=1:length(mserStats)
    text_str{ii} = num2str(ii);
end
length(mserStats);
afterBBoxes = insertText(afterBBoxes,bbox(:,1:2),text_str,'FontSize',12,'BoxColor','red','BoxOpacity',0,'TextColor','green');

end