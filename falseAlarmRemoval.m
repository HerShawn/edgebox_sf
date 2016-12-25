
function [textBBoxes]=falseAlarmRemoval(g,IntraTextBboxs,textBBoxes,bbox,txtBBoxes)

filterIdx=find((double(textBBoxes(:,5)<3)+double(textBBoxes(:,6)>1))==2);
textBBoxesNum=length(filterIdx);
leftIdx=[];
for ii=1:textBBoxesNum
    bboxIdx=filterIdx(ii);
    if(length(find(IntraTextBboxs(IntraTextBboxs(:,5)==bboxIdx,4)>textBBoxes(bboxIdx,4)/2))>1)
        leftIdx=[leftIdx bboxIdx];
    end
end
leftIdx=[leftIdx (find(textBBoxes(:,5)>2))'];
[~,sortIdx]=sort(leftIdx);
leftIdx=leftIdx(sortIdx);
textBBoxes=textBBoxes(leftIdx,:);


end