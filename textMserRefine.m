function [IntraTextBboxs,textBBoxes,bbox]= textMserRefine(g,IntraTextBboxs,textBBoxes,bbox)

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
        bboxIdx=find(tmpBboxRatio);
        %3.终止条件1：text未探索到一个bbox，自然不再扩张，故退出循环
        if isempty(bboxIdx)
            break
        end
        %##【4.】计算tmp与探索到的bbox之间的相似度
        %4.1tmp的颜色均值和笔划宽度均值
        img=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3)-1,:);
        maxArea=floor(median(Intra(:,3).*Intra(:,4)));
        minArea=ceil(0.1*maxArea);
        [mserRegions, mserConnComp] = detectMSERFeatures(rgb2gray(img), ...
            'RegionAreaRange',[minArea maxArea],'ThresholdDelta',1);
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
            'Solidity', 'Extent', 'Euler', 'Image','PixelIdxList');
        Intrabbox = vertcat(mserStats.BoundingBox);
        w = Intrabbox(:,3);
        h = Intrabbox(:,4);
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
        textFeature(strokeWidthFilterIdx,:)=[];
        clear strokeWidthFilterIdx
        figure
        imshow(img)
        hold on
        plot(mserRegions, 'showPixelList', true,'showEllipses',false)
        title('text')
        hold off
        %4.2如果text里求不出颜色均值和笔划宽度，那就不再扩张，直接跳出
        if isempty(textFeature)
            break;
        end
        medianTextFeature=[median(textFeature(:,1)) median(textFeature(:,2)) median(textFeature(:,3)) median(textFeature(:,4))];
        %4.3 每个待纳入bbox的颜色均值和笔划宽度均值
        acceptBboxIdx=[];
        for k=1:numel(bboxIdx)
            mserBbox=bbox(bboxIdx(k),:);
            im=g(mserBbox(1,2):mserBbox(1,2)+mserBbox(1,4),mserBbox(1,1):mserBbox(1,1)+mserBbox(1,3),:);
            maxArea=floor(mserBbox(1,3)*mserBbox(1,4));
            minArea=ceil(maxArea/5);
            [mserRegions, mserConnComp] = detectMSERFeatures(rgb2gray(im), ...
                'RegionAreaRange',[minArea maxArea],'ThresholdDelta',1);
            mserStats = regionprops(mserConnComp,'Image','PixelIdxList');
            bboxFeature=zeros(numel(mserStats),4);
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
                imr=im(:,:,1);
                bboxFeature(j,1)=median(imr(mserStats(j).PixelIdxList));
                img=im(:,:,2);
                bboxFeature(j,2)=median(img(mserStats(j).PixelIdxList));
                imb=im(:,:,3);
                bboxFeature(j,3)=median(imb(mserStats(j).PixelIdxList));
                bboxFeature(j,4)=median(strokeWidthValues);
            end
            mserRegions(strokeWidthFilterIdx) = [];
            mserStats(strokeWidthFilterIdx) = [];
            bboxFeature(strokeWidthFilterIdx,:)=[];
            clear strokeWidthFilterIdx
            figure
            imshow(im)
            hold on
            plot(mserRegions, 'showPixelList', true,'showEllipses',false)
            title('bbox')
            hold off
            if isempty(bboxFeature)
                continue;
            end
            %4.3 计算text与bbox的相似度
            medianBboxFeature=[median(bboxFeature(:,1)) median(bboxFeature(:,2)) median(bboxFeature(:,3)) median(bboxFeature(:,4))];
            diffr=abs(medianTextFeature(1,1)-medianBboxFeature(1,1));
            diffg=abs(medianTextFeature(1,2)-medianBboxFeature(1,2));
            diffb=abs(medianTextFeature(1,3)-medianBboxFeature(1,3));
            diffsw=max(medianTextFeature(1,3)/medianBboxFeature(1,3),medianBboxFeature(1,3)/medianTextFeature(1,3));
            if diffr<20 && diffg<20 && diffb<20 && diffsw<1.5
                acceptBboxIdx=[acceptBboxIdx bboxIdx(k)];
            end
        end
        
        %5. 若不存在与text相似的bbox，则推出循环。
        if isempty(acceptBboxIdx)
            close all
            break;
        end
        
        %6.纳入bbox到text中：text外观改变；将纳入的bbox从bbox集合移到intra集合中
        %6.1 改变text外观      
        for t=1:numel(acceptBboxIdx)     
            xmin=min(textBBoxes(t,1),bbox(acceptBboxIdx(t),1));
            ymin=min(textBBoxes(t,2),bbox(acceptBboxIdx(t),2));
            xmax=max(textBBoxes(t,1)+textBBoxes(t,3)-1,bbox(acceptBboxIdx(t),1)+bbox(acceptBboxIdx(t),3)-1);
            ymax=max(textBBoxes(t,2)+textBBoxes(t,4)-1,bbox(acceptBboxIdx(t),2)+bbox(acceptBboxIdx(t),4)-1);
            textBBoxes(t,1)=xmin;
            textBBoxes(t,2)=ymin;
            textBBoxes(t,3)=xmax-xmin+1;
            textBBoxes(t,4)=ymax-ymin+1;     
        end
         %6.2 将纳入的bbox从bbox集合移到intra集合中
         tmpBbox=bbox(acceptBboxIdx,:);
         tmpBbox(:,5)=ii;
         IntraTextBboxs=[IntraTextBboxs ;tmpBbox];
         bbox(acceptBboxIdx,:)=[];           
         close all
    end  
end
end