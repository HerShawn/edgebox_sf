
function MSTB_mser_25(g,textBBoxes,img_value)
textBBoxesNum=size(textBBoxes,1);
mserBBoxes=[];
for ii=1:textBBoxesNum
    gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3)-1,:);
    img = rgb2gray(gBbox);
    maxArea=ceil(size(img,1)*size(img,1)*9/16);
    minArea=round(maxArea/25);
    bboxes=[];
    % 为提高mser检出率，将阈值从1到10递增（以后试下多通道的方式）
    for jj=1:10
        [~, mserConnComp] = detectMSERFeatures(img, ...
            'RegionAreaRange',[minArea maxArea],'ThresholdDelta',jj);
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
            'Solidity', 'Extent', 'Euler', 'Image');
        bbox = vertcat(mserStats.BoundingBox);
        if isempty(bbox)
            continue
        end
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = aspectRatio' > 1;
        filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
        filterIdx = filterIdx | [mserStats.Solidity] < .3;
        filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
        filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
        mserStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);
        bboxes=[bboxes;bbox];
    end
    if isempty(bboxes)
        continue
    end
    [mserBBoxe, ~]=selectStrongestBbox(bboxes(:,1:4),bboxes(:,3).*bboxes(:,4),'RatioType','Min','OverlapThreshold',0.9);
    mserBBoxesNum=size(mserBBoxe,1);
    mserBBoxe(:,1)=mserBBoxe(:,1)+textBBoxes(ii,1);
    mserBBoxe(:,2)=mserBBoxe(:,2)+textBBoxes(ii,2);
    mserIdx=ones(mserBBoxesNum,1)*ii;
    mserBBoxes=[mserBBoxes; [ mserBBoxe mserIdx]];
    textBBoxes(ii,6)=mserBBoxesNum;
end
aftertext = insertShape(g, 'Rectangle', mserBBoxes(:,1:4),'LineWidth',1,'Color','cyan');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==1),1:4),'LineWidth',3,'Color','red');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)==2),1:4),'LineWidth',3,'Color','yellow');
aftertext = insertShape(aftertext, 'Rectangle', textBBoxes( find(textBBoxes(:,5)>2),1:4),'LineWidth',3,'Color','green');
textBBoxesNum=size(textBBoxes,1);
for kk=1:textBBoxesNum
    text_str{kk} = num2str(kk);
end
aftertext= insertText(aftertext,textBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
clear text_str
save_name=[img_value '-morphology-' num2str(ii) '.bmp'];
imwrite(aftertext,save_name);
end
