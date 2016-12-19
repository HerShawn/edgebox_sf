function [yellowRedNum,textBBoxes,bbox]=textRefine_12_19(g,img_value,textBBoxes)


%% ��1����Ԥ����

% #####��1.0��Ӧ�ð����̡��졢�Ƶ���Ŀ��λ�÷ֲ����趨һЩ����  

% ��1.1����textBBoxes����90%���ص�ʱ�����յȼ�����>��>�죩��NMS
[~,~,selectedIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
textBBoxes=textBBoxes(selectedIdx,:);
yellowRedNum=length( find(textBBoxes(:,5)<=2));
textBBoxesNum=size(textBBoxes,1);

% #####��1.2��{�졢��}���̽���ʱȥ�������ŵ��ߵȼ�text�Ĳ����� ����87,229�ȹ����졢�ƵĴ���


%% ��2��: mser����

% ��2.1����ȡmser
img=rgb2gray(g);
maxH=max(textBBoxes(:,4));
maxArea=ceil(maxH*maxH*9/16);
minArea=min(floor(size(g,1)/100),floor(size(g,2)/100)).^2;
[~, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[minArea maxArea],'ThresholdDelta',1);
mserStats = regionprops(mserConnComp, 'BoundingBox');
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
filterIdx = aspectRatio' > 2;

% ##��2.2����textBBoxes�����bboxȫ��ȥ��: ������textBBoxes�飬Ȼ��ȥbbox
txtOverlapRatio=txtOverlap(textBBoxes,textBBoxes);
n = size(txtOverlapRatio,1);
txtOverlapRatio(1:n+1:n^2) = 0;
gh = graph(txtOverlapRatio);
componentIndices = conncomp(gh);
%textBBoxes(:,7)��¼��textBBoxes�����ĸ�txtBBoxes��
textBBoxes=[textBBoxes componentIndices'];
%
ymin=textBBoxes(:,2);
ymax = ymin + textBBoxes(:,4) - 1;
ymin = accumarray(componentIndices', ymin, [], @min);
ymax = accumarray(componentIndices', ymax, [], @max);
%txtBBoxes�������õ���
txtBBoxes=[ones(length(ymin),1)  ymin   ones(length(ymin),1)*size(g,2)  ymax-ymin+1 ];
% ����ʾһ�� txtBBoxes��
g = insertShape(g, 'FilledRectangle', txtBBoxes(:,1:4), 'color', 'white','Opacity',0.5);
%����txtBBoxes���ڵ�bboxҪȫ��ȥ��
txtBBoxOverlapRatio=txtBBoxOverlap(txtBBoxes,bbox);
filterIdx = filterIdx | sum(txtBBoxOverlapRatio)==0;
%
filterIdx = filterIdx | h' > maxH ;
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

% ��2.3�� ��mser��text Bbox��ϵ����
textMserOverlapRatio=textMserOverlap(textBBoxes,bbox);
bboxNum=size(bbox,1);
bboxIdx=zeros(bboxNum,1);
bbox=[bbox bboxIdx];
for ii=1:textBBoxesNum
    mserBBoxes=find(textMserOverlapRatio(ii,:));
    if isempty(mserBBoxes)
        continue
    end
    %bbox��¼��bbox�����ĸ�text(���ڲ�)������text�ⲿ��bbox��:,5����Ϊ0��
    for jj=1:length(mserBBoxes)
        bbox(mserBBoxes(jj),5)=ii;
    end
end

% ��2.4�� ������txt,text�򣬼�mser��ϵ����  ####���Ƿ��б�Ҫ��һ������������Ժ��ٿ�����[�и���������Ϊһ�������CNN response]
% ��IntraTextBbox��bbox�ڷֱ�NMS���Ͳ���NMS����Ҫ��bbox
IntraTextBboxs=[];
for ii=1:size(txtBBoxes,1)
    textIdx=find(textBBoxes(:,7)==ii);
    for jj=1:length(textIdx)
        IntraTextBbox=bbox(find(bbox(:,5)==textIdx(jj)),:);
        %mser���ֳ����飬���ǲ���text�ڵ�mser����bbox��
        bbox(find(bbox(:,5)==textIdx(jj)),:)=[];
        [~,~,selectedIntraIdx]=selectStrongestBbox(IntraTextBbox(:,1:4),IntraTextBbox(:,3).*IntraTextBbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
        IntraTextBbox=IntraTextBbox(selectedIntraIdx,:);
        %mser���ֳ����飬��text�ڵ�mser����IntraTextBboxs�ڣ��Ұ������С��NMS
        IntraTextBboxs=[IntraTextBboxs;IntraTextBbox];
        %textBBoxes(ii,6)��¼��text������mser��Ŀ
        textBBoxes(textIdx(jj),6)=size(IntraTextBbox,1);
    end
end
[~,~,selectedBboxIdx]=selectStrongestBbox(bbox(:,1:4),bbox(:,3).*bbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
bbox=bbox(selectedBboxIdx,:);

% #####��2.5��{�졢��}��text 1.δ��ȡ��bbox��2.��ȡ�����ҵ�bbox��������������bbox�������ģ�
% ���⣬ÿ��text�ڵ�mser bboxesҲҪ�����£����У�ÿ�е���б�ȣ���



%% ####��ؼ��㷨��3��: ����refine textBBoxes
[IntraTextBboxs,textBBoxes,bbox]=textMserRefine(g,IntraTextBboxs,textBBoxes,bbox);

% 3.2 
[textBBoxes]=falseAlarmRemoval(g,IntraTextBboxs,textBBoxes,bbox,txtBBoxes);

%% ����ʾ���� ÿ��textBBoxes
textBBoxesNum=size(textBBoxes,1);
if textBBoxesNum==0
    img_value
    img2=g;
else
    img2 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
    img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
    img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
    for kk=1:textBBoxesNum
        text_str{kk} = num2str(kk);
    end
    img2= insertText(img2,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
end

clear text_str
% ����ʾ���� ÿ�� mser bboxes
img3 = insertShape(img2, 'Rectangle', bbox(:,1:4), 'color', 'cyan');
img4 = insertShape(img3, 'Rectangle', IntraTextBboxs(:,1:4), 'color', 'black');
saveName=[img_value '-mse.bmp'];
imwrite(img4,saveName);
end