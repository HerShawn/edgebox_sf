function textRefine_12_9(g,img_value,textBBoxes)
% img1 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
% img1 = insertShape(img1, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
% img1 = insertShape(img1, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
% saveName=[img_value '-1.bmp'];
% imwrite(img1,saveName);
%% 【1】：预处理
% 【1.1】NMS
[~,~,selectedIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
textBBoxes=textBBoxes(selectedIdx,:);
img2 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
% saveName=[img_value '-2.bmp'];
% imwrite(img2,saveName);
%【1.2】红、黄未取H>0.5的bbox则去掉
%首先，需要提取mser
img=rgb2gray(g);
maxH=max(textBBoxes(:,4));
maxArea=ceil(maxH*maxH*9/16);
minArea=50;
[~, mserConnComp] = detectMSERFeatures(img, ...
    'RegionAreaRange',[minArea maxArea],'ThresholdDelta',2);
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;
filterIdx = aspectRatio' > 7;
filterIdx = filterIdx | h' > maxH ;
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);

[bbox,~,~]=selectStrongestBbox(bbox(:,1:4),bbox(:,3).*bbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
img3 = insertShape(img2, 'Rectangle', bbox(:,1:4), 'color', 'yellow');
saveName=[img_value '-mse.bmp'];
imwrite(img3,saveName);
%% textBBoxes间如何算作一行（可拼接）；应该再结合上距离信息？
% txtOverlapRatio=txtOverlap(textBBoxes,textBBoxes);
% n = size(txtOverlapRatio,1);
% txtOverlapRatio(1:n+1:n^2) = 0;
% gh = graph(txtOverlapRatio);
% componentIndices = conncomp(gh);
% ymin=textBBoxes(:,2);
% ymax = ymin + textBBoxes(:,4) - 1;
% ymin = accumarray(componentIndices', ymin, [], @min);
% ymax = accumarray(componentIndices', ymax, [], @max);
% txtBBoxes=[ones(length(ymin),1)*3  ymin   ones(length(ymin),1)*size(g,2)-4  ymax-ymin+1 ];

end