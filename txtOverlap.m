
function overlapRatio = txtOverlap(bboxA, bboxB)

y1BboxA = bboxA(:, 2);
y2BboxA = y1BboxA + bboxA(:, 4);

y1BboxB = bboxB(:, 2);
y2BboxB = y1BboxB + bboxB(:, 4);

overlapRatio = zeros(size(bboxA,1),size(bboxB,1), 'like', bboxA);

for m = 1:size(bboxA,1)
    for n = 1:size(bboxB,1)
        y1 = max(y1BboxA(m), y1BboxB(n));
        y2 = min(y2BboxA(m), y2BboxB(n));
        h = y2 - y1;
        if h <= 0
            continue;
        end
        overlapRatio(m,n) = (y2-y1)/(max(y2BboxA(m), y2BboxB(n))-min(y1BboxA(m), y1BboxB(n)));
        if overlapRatio(m,n)<=0.5
            overlapRatio(m,n)=0;
        end
    end
end
end

