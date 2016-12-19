function [yellowRedNum,textBBoxes,bbox]=textRefine_12_19(g,img_value,textBBoxes)


%% 【1】：预处理

% #####【1.0】应该按照绿、红、黄的数目，位置分布，设定一些规则  

% 【1.1】当textBBoxes存在90%的重叠时，按照等级（绿>黄>红）来NMS
[~,~,selectedIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
textBBoxes=textBBoxes(selectedIdx,:);
yellowRedNum=length( find(textBBoxes(:,5)<=2));
textBBoxesNum=size(textBBoxes,1);

% #####【1.2】{红、黄}与绿交叠时去掉，干扰到高等级text的操作； 例如87,229等过量红、黄的处理。


%% 【2】: mser分组

% 【2.1】提取mser
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

% ##【2.2】在textBBoxes组外的bbox全部去掉: 先做好textBBoxes组，然后去bbox
txtOverlapRatio=txtOverlap(textBBoxes,textBBoxes);
n = size(txtOverlapRatio,1);
txtOverlapRatio(1:n+1:n^2) = 0;
gh = graph(txtOverlapRatio);
componentIndices = conncomp(gh);
%textBBoxes(:,7)记录着textBBoxes属于哪个txtBBoxes组
textBBoxes=[textBBoxes componentIndices'];
%
ymin=textBBoxes(:,2);
ymax = ymin + textBBoxes(:,4) - 1;
ymin = accumarray(componentIndices', ymin, [], @min);
ymax = accumarray(componentIndices', ymax, [], @max);
%txtBBoxes就是做好的组
txtBBoxes=[ones(length(ymin),1)  ymin   ones(length(ymin),1)*size(g,2)  ymax-ymin+1 ];
% 【显示一】 txtBBoxes组
g = insertShape(g, 'FilledRectangle', txtBBoxes(:,1:4), 'color', 'white','Opacity',0.5);
%不在txtBBoxes组内的bbox要全部去掉
txtBBoxOverlapRatio=txtBBoxOverlap(txtBBoxes,bbox);
filterIdx = filterIdx | sum(txtBBoxOverlapRatio)==0;
%
filterIdx = filterIdx | h' > maxH ;
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

% 【2.3】 将mser与text Bbox联系起来
textMserOverlapRatio=textMserOverlap(textBBoxes,bbox);
bboxNum=size(bbox,1);
bboxIdx=zeros(bboxNum,1);
bbox=[bbox bboxIdx];
for ii=1:textBBoxesNum
    mserBBoxes=find(textMserOverlapRatio(ii,:));
    if isempty(mserBBoxes)
        continue
    end
    %bbox记录该bbox属于哪个text(在内部)，或在text外部（bbox（:,5）设为0）
    for jj=1:length(mserBBoxes)
        bbox(mserBBoxes(jj),5)=ii;
    end
end

% 【2.4】 将分组txt,text框，及mser联系起来  ####？是否有必要按一组组来？这个以后再看！！[有个理由是因为一组可以用CNN response]
% 在IntraTextBbox和bbox内分别NMS，就不会NMS掉重要的bbox
IntraTextBboxs=[];
for ii=1:size(txtBBoxes,1)
    textIdx=find(textBBoxes(:,7)==ii);
    for jj=1:length(textIdx)
        IntraTextBbox=bbox(find(bbox(:,5)==textIdx(jj)),:);
        %mser被分成两组，凡是不在text内的mser都在bbox中
        bbox(find(bbox(:,5)==textIdx(jj)),:)=[];
        [~,~,selectedIntraIdx]=selectStrongestBbox(IntraTextBbox(:,1:4),IntraTextBbox(:,3).*IntraTextBbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
        IntraTextBbox=IntraTextBbox(selectedIntraIdx,:);
        %mser被分成两组，在text内的mser都在IntraTextBboxs内，且按面积大小来NMS
        IntraTextBboxs=[IntraTextBboxs;IntraTextBbox];
        %textBBoxes(ii,6)记录该text包含的mser数目
        textBBoxes(textIdx(jj),6)=size(IntraTextBbox,1);
    end
end
[~,~,selectedBboxIdx]=selectStrongestBbox(bbox(:,1:4),bbox(:,3).*bbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
bbox=bbox(selectedBboxIdx,:);

% #####【2.5】{红、黄}的text 1.未提取到bbox；2.提取到杂乱的bbox（包括上下两层bbox）这样的；
% 另外，每种text内的mser bboxes也要清理下（几行？每行的倾斜度？）



%% ####最关键算法【3】: 迭代refine textBBoxes
[IntraTextBboxs,textBBoxes,bbox]=textMserRefine(g,IntraTextBboxs,textBBoxes,bbox);

% 3.2 
[textBBoxes]=falseAlarmRemoval(g,IntraTextBboxs,textBBoxes,bbox,txtBBoxes);

%% 【显示二】 每个textBBoxes
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
% 【显示三】 每个 mser bboxes
img3 = insertShape(img2, 'Rectangle', bbox(:,1:4), 'color', 'cyan');
img4 = insertShape(img3, 'Rectangle', IntraTextBboxs(:,1:4), 'color', 'black');
saveName=[img_value '-mse.bmp'];
imwrite(img4,saveName);
end