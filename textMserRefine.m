function textMserRefine(g,IntraTextBboxs,textBBoxes,bbox)

for ii=1:size(textBBoxes,1)
    
    while(1)
        %1.扩展text,得到tmp
        tmp_x=max(1,textBBoxes(ii,1)-textBBoxes(ii,4));
        tmp_x2=min(textBBoxes(ii,1)+textBBoxes(ii,3)+textBBoxes(ii,4),size(g,2));
        tmp_w=tmp_x2-tmp_x;
        tmp=[tmp_x textBBoxes(ii,2) tmp_w textBBoxes(ii,4)];
        %2.求与tmp有overlap的mser bbox
        Intra=IntraTextBboxs(IntraTextBboxs(:,5)==ii,:);
        tmpBboxRatio=bboxOverlapRatio_refine(tmp,bbox(:,1:4),Intra);
        %3.终止条件1：text未探索到一个bbox，自然不再扩张，故退出循环
        if isempty(find(tmpBboxRatio))
            break
        end
        %##【4.】计算tmp与探索到的bbox之间的相似度
        %tmp的颜色均值和笔划宽度均值
        img=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4),textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3),:);
        maxArea=floor(median(Intra(:,3).*Intra(:,4)));
        minArea=ceil(0.1*maxArea);
        [mserRegions, mserConnComp] = detectMSERFeatures(rgb2gray(img), ...
            'RegionAreaRange',[minArea maxArea],'ThresholdDelta',1);
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
            'Solidity', 'Extent', 'Euler', 'Image','PixelIdxList');
        bbox = vertcat(mserStats.BoundingBox);
        w = bbox(:,3);
        h = bbox(:,4);
        aspectRatio = w./h;
        filterIdx = aspectRatio' > 7;
        filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
        filterIdx = filterIdx | [mserStats.Solidity] < .3;
        filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
        filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
        mserStats(filterIdx) = [];
        mserRegions(filterIdx) = [];
        clear filterIdx
        strokeWidthThreshold = 0.4;
        textFeature=zeros(numel(mserStats),4);
        for j = 1:numel(mserStats)
            regionImage = mserStats(j).Image;
            regionImage = padarray(regionImage, [1 1], 0);
            distanceImage = bwdist(~regionImage);
            skeletonImage = bwmorph(regionImage, 'thin', inf);
            strokeWidthValues = distanceImage(skeletonImage);
            strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
            strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;
            if strokeWidthFilterIdx(j)==1
                continue;
            end
            imgr=img(:,:,1);
            textFeature(j,1)=median(imgr(mserStats(j).PixelIdxList));
            imgg=img(:,:,2);
            textFeature(j,2)=median(imgg(mserStats(j).PixelIdxList));
            imgb=img(:,:,3);
            textFeature(j,3)=median(imgb(mserStats(j).PixelIdxList));
            textFeature(j,4)=median(strokeWidthValues);
        end
        mserRegions(strokeWidthFilterIdx) = [];
        mserStats(strokeWidthFilterIdx) = [];
        clear strokeWidthFilterIdx
        figure
        imshow(img)
        hold on
        plot(mserRegions, 'showPixelList', true,'showEllipses',false)
        title('MSER regions')
        hold off
        
        medianTextFeature=median(textFeature);
        
    end
    
end

end