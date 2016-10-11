

function overlapRatio = bboxOverlap(bboxA, bboxB)
% Compute the overlap ratio between every row in bboxA and bboxB

% left top corner
x1BboxA = bboxA(:, 1);
y1BboxA = bboxA(:, 2);
% right bottom corner
x2BboxA = x1BboxA + bboxA(:, 3);
y2BboxA = y1BboxA + bboxA(:, 4);

x1BboxB = bboxB(:, 1);
y1BboxB = bboxB(:, 2);
x2BboxB = x1BboxB + bboxB(:, 3);
y2BboxB = y1BboxB + bboxB(:, 4);

% area of the bounding box
areaA = bboxA(:, 3) .* bboxA(:, 4);
areaB = bboxB(:, 3) .* bboxB(:, 4);

overlapRatio = zeros(size(bboxA,1),size(bboxB,1), 'like', bboxA);

for m = 1:size(bboxA,1)
    for n = 1:size(bboxB,1)
        % compute the corners of the intersect
        x1 = max(x1BboxA(m), x1BboxB(n));
        y1 = max(y1BboxA(m), y1BboxB(n));
        x2 = min(x2BboxA(m), x2BboxB(n));
        y2 = min(y2BboxA(m), y2BboxB(n));
        
        %【1】 没有交集就直接计算下一对
        w = x2 - x1;
        if w <= 0
            continue;
        end
        
        h = y2 - y1;
        if h <= 0
            continue;
        end
        %【2】一对bbox间的height不能相差太多，否则不能构成文本行
    
        if min(abs(y1BboxA(m)-y2BboxA(m)),abs(y1BboxB(n)-y2BboxB(n)))/max(abs(y1BboxA(m)-y2BboxA(m)),abs(y1BboxB(n)-y2BboxB(n)))>0.6 
             %【3】一对bbox之间位置不能太偏移
            if  abs(max(y1BboxA(m),y1BboxB(n))-min(y2BboxA(m),y2BboxB(n)))/max(abs(y1BboxA(m)-y2BboxA(m)),abs(y1BboxB(n)-y2BboxB(n)))>0.25
                intersectAB = w * h;       
                overlapRatio(m,n) = intersectAB/(areaA(m)+areaB(n)-intersectAB);
            end
        end
    end
end
end

