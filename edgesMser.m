%%
% [1] Chen, Huizhong, et al. "Robust Text Detection in Natural Images with Edge-Enhanced Maximally Stable Extremal Regions." Image Processing (ICIP), 2011 18th IEEE International Conference on. IEEE, 2011.
% [2] Gonzalez, Alvaro, et al. "Text location in complex images." Pattern Recognition (ICPR), 2012 21st International Conference on. IEEE, 2012.
% [3] Li, Yao, and Huchuan Lu. "Scene text detection via stroke width." Pattern Recognition (ICPR), 2012 21st International Conference on. IEEE, 2012.
% [4] Neumann, Lukas, and Jiri Matas. "Real-time scene text localization and recognition." Computer Vision and Pattern Recognition (CVPR), 2012 IEEE Conference on. IEEE, 2012.
%

close all
clear
clc
do_dir='D:\edgebox-contour-neumann三种检测方法的比较\';
dir_img = dir([do_dir 'Challenge2_Test_Task12_Images\*.jpg']);
num_img = length(dir_img);
for indexImg = 1:1
   
   
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = [do_dir 'Challenge2_Test_Task12_Images\' img_value '.jpg'];
    
    %% Step 1: Detect Candidate Text Regions Using MSER
    colorImage_temp = imread(img_name);
%     if(size(colorImage_temp,1)>640)
%     colorImage=imresize(co lorImage_temp,[640,NaN]);
%     else
        colorImage=colorImage_temp;
%     end
    I = rgb2gray(colorImage);
    
    % Detect MSER regions.
    [mserRegions, mserConnComp] = detectMSERFeatures(I, ...
        'RegionAreaRange',[100 10000],'ThresholdDelta',1);
    
    figure
    imshow(I)
    hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('MSER regions')
    hold off
    save_name=[img_value '-1.jpg'];
    print(gcf, '-dpng', save_name);
    close
    
    
    %% Step 2: Remove Non-Text Regions Based On Basic Geometric Properties
    % Use regionprops to measure MSER properties
    mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');
    
    % Compute the aspect ratio using bounding box data.
    bbox = vertcat(mserStats.BoundingBox);
    w = bbox(:,3);
    h = bbox(:,4);
    aspectRatio = w./h;
    
    % Threshold the data to determine which regions to remove. These thresholds
    % may need to be tuned for other images.
    filterIdx = aspectRatio' > 7;
    filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
    filterIdx = filterIdx | [mserStats.Solidity] < .3;
    filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
    filterIdx = filterIdx | [mserStats.EulerNumber] < -4;
    
    % Remove regions
    mserStats(filterIdx) = [];
    mserRegions(filterIdx) = [];
    clear filterIdx
    
    % Show remaining regions
    figure
    imshow(I)
    hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('After Removing Non-Text Regions Based On Geometric Properties')
    hold off
    save_name=[img_value '-2.jpg'];
    print(gcf, '-dpng', save_name);
    close
    
    %% Step 3: Remove Non-Text Regions Based On Stroke Width Variation
    % Threshold the stroke width variation metric
    strokeWidthThreshold = 0.4;
    
    % Process the remaining regions
    for j = 1:numel(mserStats)
        
        regionImage = mserStats(j).Image;
        regionImage = padarray(regionImage, [1 1], 0);
        
        distanceImage = bwdist(~regionImage);
        skeletonImage = bwmorph(regionImage, 'thin', inf);
        
        strokeWidthValues = distanceImage(skeletonImage);
        
        strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
        
        strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;
        
    end
    
    % Remove regions based on the stroke width variation
    mserRegions(strokeWidthFilterIdx) = [];
    mserStats(strokeWidthFilterIdx) = [];
    clear strokeWidthFilterIdx
    
    % Show remaining regions
    figure
    imshow(I)
    hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('After Removing Non-Text Regions Based On Stroke Width Variation')
    hold off
    save_name=[img_value '-3.jpg'];
    print(gcf, '-dpng', save_name);
    close
    
    %% Step 4: Merge Text Regions For Final Detection Result
    % Get bounding boxes for all the regions
    bboxes = vertcat(mserStats.BoundingBox);
    
    % Convert from the [x y width height] bounding box format to the [xmin ymin
    % xmax ymax] format for convenience.
    xmin = bboxes(:,1);
    ymin = bboxes(:,2);
    xmax = xmin + bboxes(:,3) - 1;
    ymax = ymin + bboxes(:,4) - 1;
    
    % Expand the bounding boxes by a small amount.
    expansionAmount = 0.02;
    xmin = (1-expansionAmount) * xmin;
    ymin = (1-expansionAmount) * ymin;
    xmax = (1+expansionAmount) * xmax;
    ymax = (1+expansionAmount) * ymax;
    
    % Clip the bounding boxes to be within the image bounds
    xmin = max(xmin, 1);
    ymin = max(ymin, 1);
    xmax = min(xmax, size(I,2));
    ymax = min(ymax, size(I,1));
    
    % Show the expanded bounding boxes
    expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
    IExpandedBBoxes = insertShape(colorImage,'Rectangle',expandedBBoxes,'LineWidth',3);
    
    figure
    imshow(IExpandedBBoxes)
    title('Expanded Bounding Boxes Text')
    save_name=[img_value '-4.jpg'];
    print(gcf, '-dpng', save_name);
    close
    
    %% Use the bboxOverlapRatio function to compute the pair-wise
    % overlap ratios for all the expanded bounding boxes,
    % then use graph to find all the connected regions.
    % Compute the overlap ratio
    overlapRatio = bboxOverlapRatio(expandedBBoxes, expandedBBoxes);
    
    % Set the overlap ratio between a bounding box and itself to zero to
    % simplify the graph representation.
    n = size(overlapRatio,1);
    overlapRatio(1:n+1:n^2) = 0;
    
    % Create the graph
    g = graph(overlapRatio);
    
    % Find the connected text regions within the graph
    componentIndices = conncomp(g);
    
    %% The output of conncomp are indices to the connected text regions
    % to which each bounding box belongs. Use these indices to merge multiple
    % neighboring bounding boxes into a single bounding box by computing the
    % minimum and maximum of the individual bounding boxes that make up each connected component.
    
    % Merge the boxes based on the minimum and maximum dimensions.
    xmin = accumarray(componentIndices', xmin, [], @min);
    ymin = accumarray(componentIndices', ymin, [], @min);
    xmax = accumarray(componentIndices', xmax, [], @max);
    ymax = accumarray(componentIndices', ymax, [], @max);
    
    % Compose the merged bounding boxes using the [x y width height] format.
    textBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
    
    %% Finally, before showing the final detection results,
    % suppress false text detections by removing bounding boxes
    % made up of just one text region. This removes isolated regions that
    % are unlikely to be actual text given that text is usually found in groups (words and sentences).
    
    % Remove bounding boxes that only contain one text region
    numRegionsInGroup = histcounts(componentIndices);
    textBBoxes(numRegionsInGroup == 1, :) = [];
    
    % Show the final text detection result.
    ITextRegion = insertShape(colorImage, 'Rectangle', textBBoxes,'LineWidth',3);
    
    figure
    imshow(ITextRegion)
    title('Detected Text')
    save_name=[img_value '-5.jpg'];
    print(gcf, '-dpng', save_name);
    close
    
    %%  Step 5: Recognize Detected Text Using OCR
    ocrtxt = ocr(I, textBBoxes);
    [ocrtxt.Text]
    
   
end