function [yellowRedNum,textBBoxes,bbox]=textRefine_12_12(g,img_value,textBBoxes)


%% 【1】：预处理
% 【1.1】{红、黄}数目超过10个时删去
% 【1.2】当textBBoxes存在90%的重叠时，按照等级（绿>黄>红）来NMS
[~,~,selectedIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
textBBoxes=textBBoxes(selectedIdx,:);
yellowRedNum=length( find(textBBoxes(:,5)<=2))
textBBoxesNum=size(textBBoxes,1);
% 【1.3】{红、黄}与绿交叠超10%时去掉


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
% 【2.2】r在textBBoxes组外的bbox全部去掉: 先做好textBBoxes组，然后去bbox
filterIdx = filterIdx | h' > maxH ;
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);
% 【2.3】 text内部的mser，NMS：没有/两层 则删去该text
textMserOverlapRatio=textMserOverlap(textBBoxes,bbox);
bboxNum=size(bbox,1);
bboxIdx=zeros(bboxNum,1);
bbox=[bbox bboxIdx];
for ii=1:textBBoxesNum
    %textBBoxes(ii,6)记录该text包含的mser数目
    textBBoxes(ii,6)=length( find(textMserOverlapRatio(ii,:)));
    mserBBoxes=find(textMserOverlapRatio(ii,:));
    if isempty(mserBBoxes)
        continue
    end
    %bbox记录该bbox属于哪个text
    for jj=1:length(mserBBoxes)
        bbox(mserBBoxes(jj),5)=ii;
    end
end
img2 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
textBBoxesNum=size(textBBoxes,1);
if textBBoxesNum==0
    img_value
    return
end
for kk=1:textBBoxesNum
    text_str{kk} = num2str(kk);
end
img2= insertText(img2,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
clear text_str
img3 = insertShape(img2, 'Rectangle', bbox(:,1:4), 'color', 'cyan');
img_value
saveName=[img_value '-mse.bmp'];
imwrite(img3,saveName);


%% 【3】: 迭代refine textBBoxes

end