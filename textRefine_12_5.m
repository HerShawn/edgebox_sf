function textRefine_12_5(g,img_value,textBBoxes)
%% 光靠textBBoxes(:,5)来决定textBBoxes间的NMS不够； 还应该结合MSER等其他信息？
[textBBoxes,~,~]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
%% textBBoxes间如何算作一行（可拼接）；应该再结合上距离信息？
txtOverlapRatio=txtOverlap(textBBoxes,textBBoxes);
n = size(txtOverlapRatio,1);
txtOverlapRatio(1:n+1:n^2) = 0;
gh = graph(txtOverlapRatio);
componentIndices = conncomp(gh);
ymin=textBBoxes(:,2);
ymax = ymin + textBBoxes(:,4) - 1;
ymin = accumarray(componentIndices', ymin, [], @min);
ymax = accumarray(componentIndices', ymax, [], @max);
txtBBoxes=[ones(length(ymin),1)*3  ymin   ones(length(ymin),1)*size(g,2)-4  ymax-ymin+1 ];
%% 显示
color=cell(1,size(txtBBoxes,1));
for ii=1:size(txtBBoxes,1)
    idx=mod(ii,7);
    switch idx
        case 1
            str='blue';
        case 2
            str='green';
        case 3
            str='red';
        case 4
            str='cyan';
        case 5
            str='magenta';
        case 6
            str='yellow';
        case 0
            str='black';
    end
    color(1,ii)={str};
end
clear str
aftertxtBBoxes = insertShape(g, 'Rectangle', txtBBoxes,'LineWidth',2, 'color', color);
aftertxtBBoxes = insertShape(aftertxtBBoxes, 'FilledRectangle', textBBoxes(:,1:4), 'color', 'white','Opacity',0.5);
%% 在txtBBoxes中提取mser，并显示在原图上
textBBoxesNum=size(txtBBoxes,1);
mserBBoxes=[];
for ii=1:textBBoxesNum
    gBbox=g(txtBBoxes(ii,2):txtBBoxes(ii,2)+txtBBoxes(ii,4)-1,1:size(g,2),:);
    imgo=rgb2gray(gBbox);
    img = 255-imgo;
    maxArea=ceil(size(img,1)*size(img,1)*9/16);
    minArea=round(maxArea/25);
    [~, mserConnComp] = detectMSERFeatures(img, ...
        'RegionAreaRange',[minArea maxArea],'ThresholdDelta',2);
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
%     filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
%     filterIdx = filterIdx | [mserStats.Solidity] < .3;
%     filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
%     filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
    mserStats(filterIdx) = [];
    clear filterIdx
    bbox = vertcat(mserStats.BoundingBox);
    if isempty(bbox)
        continue
    end
    [mserBBoxe, ~]=selectStrongestBbox(bbox(:,1:4),bbox(:,3).*bbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
    mserBBoxe(:,2)=mserBBoxe(:,2)+txtBBoxes(ii,2);
    mserBBoxes=[mserBBoxes; mserBBoxe];
end
if isempty(mserBBoxes)
    return
end
aftertxtBBoxes = insertShape(aftertxtBBoxes, 'FilledRectangle', mserBBoxes(:,1:4), 'color', 'red','Opacity',0.6);
save_name=[img_value '-txt.bmp'];
imwrite(aftertxtBBoxes,save_name);
end