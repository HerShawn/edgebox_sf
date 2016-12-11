function [yellowRedNum,textBBoxes,bbox]=textRefine_12_9(g,img_value,textBBoxes)
% img1 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
% img1 = insertShape(img1, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
% img1 = insertShape(img1, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
% saveName=[img_value '-1.bmp'];
% imwrite(img1,saveName);
%% 【1】：预处理
% 【1.1】NMS：当textBBoxes存在重叠时，按照等级（绿>黄>红）来NMS
[~,~,selectedIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
textBBoxes=textBBoxes(selectedIdx,:);
yellowRedNum=length( find(textBBoxes(:,5)<=2))
% img2 = insertShape(g, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
% img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
% img2 = insertShape(img2, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
textBBoxesNum=size(textBBoxes,1);
% for kk=1:textBBoxesNum
%     text_str{kk} = num2str(kk);
% end
% img2= insertText(img2,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
% clear text_str
% saveName=[img_value '-2.bmp'];
% imwrite(img2,saveName);
%【1.2】滤除虚警
%【1.2.1】首先，需要提取mser
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
filterIdx = filterIdx | h' > maxH ;
mserStats(filterIdx) = [];
clear filterIdx
bbox = vertcat(mserStats.BoundingBox);
% [bbox,~,~]=selectStrongestBbox(bbox(:,1:4),bbox(:,3).*bbox(:,4),'RatioType','Min','OverlapThreshold',0.9);
% img3 = insertShape(img2, 'Rectangle', bbox(:,1:4), 'color', 'yellow');
% saveName=[img_value '-mse.bmp'];
% imwrite(img3,saveName);
% 【1.2.2】然后，将mser bboxes和text bboxes联系起来：也就是90%包裹在text内的mser才与这个text box联系
textMserOverlapRatio=textMserOverlap(textBBoxes,bbox);
bboxNum=size(bbox,1);
bboxIdx=zeros(bboxNum,1);
bbox=[bbox bboxIdx];
% removeIdx=[];
for ii=1:textBBoxesNum
    %textBBoxes(ii,6)记录该text包含的mser数目
    textBBoxes(ii,6)=length( find(textMserOverlapRatio(ii,:)));
    mserBBoxes=find(textMserOverlapRatio(ii,:));
%     if textBBoxes(ii,5)<=2 && textBBoxes(ii,6)==0
%         removeIdx=[removeIdx ii];
%     end
    if isempty(mserBBoxes)
        continue
    end
    %bbox记录该bbox属于哪个text
    for jj=1:length(mserBBoxes)
        bbox(mserBBoxes(jj),5)=ii;
    end
end
%  %不合适 【1.2.3】将不含mser的红、黄textBBoxes去掉
% textBBoxes(removeIdx,:)=[];
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