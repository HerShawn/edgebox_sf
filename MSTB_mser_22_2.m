
function MSTB_mser_22_2(g,textBBoxes,img_value)
textBBoxesNum=size(textBBoxes,1);
for ii=1:textBBoxesNum
    gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3)-1,:);
    img = rgb2gray(gBbox);
    maxArea=ceil(size(img,1)*size(img,1)/2);
    minArea=round(maxArea/25);
        %     minArea=ceil(size(img,1)*size(img,1)/25);
    bboxes=[];
    % 为提高mser检出率，将阈值从1到10递增（以后试下多通道的方式）
    for jj=1:10
        [mserRegions, mserConnComp] = detectMSERFeatures(img, ...
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
        filterIdx = aspectRatio' > 7;
        filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
        filterIdx = filterIdx | [mserStats.Solidity] < .3;
        filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
        filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
        mserStats(filterIdx) = [];
        clear filterIdx
        bbox = vertcat(mserStats.BoundingBox);
        bboxes=[bboxes;bbox];
    end
    % 对bboxes进行NMS，保留较大面积的bbox
    if isempty(bboxes)
        return
    end
    [mserBBoxes, ~]=selectStrongestBbox(bboxes(:,1:4),bboxes(:,3).*bboxes(:,4),'RatioType','Min','OverlapThreshold',0.9);
    aftermserBBoxes = insertShape(img, 'Rectangle', mserBBoxes,'LineWidth',1);
    mserBBoxesNum=size(mserBBoxes,1);
    for kk=1:mserBBoxesNum
        text_str{kk} = num2str(kk);
    end
    aftertext= insertText(aftermserBBoxes,mserBBoxes(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
    clear text_str
    if textBBoxes(ii,5)==1
        className='false';
    elseif textBBoxes(ii,5)==2
        className='weak';
    else
         className='strong';
    end
    save_name=[img_value '(' num2str(ii) ')' '-' className '(' num2str(mserBBoxesNum) ')' '.bmp'];
    imwrite(aftertext,save_name);
end
end
